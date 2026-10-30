import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../data/repositories/planner_repository.dart';
import '../../data/services/device_notification_service.dart';
import '../../data/services/voice_reminder_service.dart';
import '../../domain/models/family_models.dart';

class PlannerViewModel extends ChangeNotifier {
  final PlannerRepository _repository;
  final VoiceReminderService _voiceService;
  final DeviceNotificationService _notificationService;

  PlannerViewModel({
    required this._repository,
    required this._voiceService,
    DeviceNotificationService? notificationService,
  }) : _notificationService =
           notificationService ?? DeviceNotificationService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Internal role key mapped to the logged-in member's account ('husband' | 'wife')
  /// Used only for personal record ownership, never exposed as a switcher!
  String _memberRoleKey = 'husband';
  String get memberRoleKey => _memberRoleKey;

  String _activeDisplayName = 'İlker';
  String get activeDisplayName => _activeDisplayName;

  String _activeUserEmail = '';
  String get activeUserEmail => _activeUserEmail;

  List<String> _connectedMemberNames = const ['İlker', 'Neslihan'];
  List<String> get connectedMemberNames => _connectedMemberNames;

  /// 'all' (Benim Kişisel + Ortak) | 'personal' (Sadece Kişisel) | 'shared' (Sadece Ortak)
  String _timelineFilter = 'all';
  String get timelineFilter => _timelineFilter;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  FamilyProfile _familyProfile = const FamilyProfile(
    id: 1,
    name: 'Aydoğdu Ailesi',
    inviteCode: 'AYDOGDU26',
    city: 'Istanbul',
    country: 'Turkey',
    wakeUpTime: '05:00',
    sleepTime: '23:00',
  );
  FamilyProfile get familyProfile => _familyProfile;

  PrayerTimesDay _prayerTimes = PrayerTimesDay.fallback();
  PrayerTimesDay get prayerTimes => _prayerTimes;

  List<ScheduleBlock> _blocks = [];
  List<ScheduleBlock> get allBlocks => _blocks;

  List<FocusSession> _focusSessions = [];
  List<FocusSession> get focusSessions => _focusSessions;

  List<MedicationReminder> _medicationReminders = [];
  List<MedicationReminder> get medicationReminders => _medicationReminders;

  List<WaterTracker> _waterTrackers = [];
  List<WaterTracker> get waterTrackers => _waterTrackers;

  List<PartnerInvitation> _partnerInvitations = [];
  List<PartnerInvitation> get partnerInvitations => _partnerInvitations;

  bool _isPhoneLockShieldActive = false;
  bool get isPhoneLockShieldActive => _isPhoneLockShieldActive;

  String _activeLockdownReason =
      'Odak & Telefon Kısıtlama Modu (Sadece Aramalar)';
  String get activeLockdownReason => _activeLockdownReason;

  String? _lastSpokenReminder;
  String? get lastSpokenReminder => _lastSpokenReminder;

  bool get deviceNotificationsGranted => _notificationService.permissionGranted;

  RealtimeChannel? _realtimeChannel;
  Timer? _minuteScheduleWatcher;

  String get formattedSelectedDate =>
      _selectedDate.toIso8601String().substring(0, 10);

  WaterTracker get activeWaterTracker {
    if (_waterTrackers.isNotEmpty) return _waterTrackers.first;
    return WaterTracker(
      familyId: _familyProfile.id,
      ownerRole: _memberRoleKey,
      dailyGoalMl: 2500,
      currentIntakeMl: 1000,
      cupSizeMl: 250,
      reminderIntervalMinutes: 90,
      reminderEnabled: true,
    );
  }

  /// Blocks already filtered at DB RLS level so ONLY this user's personal blocks
  /// and 'shared' blocks exist in `_blocks`.
  List<ScheduleBlock> get filteredBlocks {
    final weekday = _selectedDate.weekday;
    final dayBlocks = _blocks.where((b) {
      if (b.isRecurringDaily) {
        return b.recurrenceDays.isEmpty || b.recurrenceDays.contains(weekday);
      }
      return b.planDate == formattedSelectedDate;
    }).toList();

    if (_timelineFilter == 'personal') {
      return dayBlocks.where((b) => b.ownerRole != 'shared').toList();
    }
    if (_timelineFilter == 'shared') {
      return dayBlocks.where((b) => b.ownerRole == 'shared').toList();
    }
    return dayBlocks;
  }

  /// Strictly private personal plans belonging ONLY to the logged-in member
  List<ScheduleBlock> get personalBlocksOnly =>
      _blocks.where((b) => b.ownerRole != 'shared').toList();

  /// Shared plans visible to both connected members
  List<ScheduleBlock> get sharedBlocksOnly =>
      _blocks.where((b) => b.ownerRole == 'shared').toList();

  /// Other connected members in the shared group (excluding current user)
  List<String> get linkedPartnerNames {
    final others = _connectedMemberNames
        .where((n) => n.toLowerCase() != _activeDisplayName.toLowerCase())
        .toList();
    return others.isEmpty ? const ['Neslihan'] : others;
  }

  int get completedCount =>
      _blocks.where((b) => b.status == 'completed').length;

  int get checkedInCount =>
      _blocks.where((b) => b.status == 'checked_in').length;

  int get skippedCount => _blocks.where((b) => b.status == 'skipped').length;

  int get takenMedicationCount =>
      _medicationReminders.where((m) => m.takenToday).length;

  double get completionRate {
    if (_blocks.isEmpty) return 0;
    final doneOrActive = completedCount + checkedInCount;
    return (doneOrActive / _blocks.length) * 100;
  }

  bool isReminderActiveFor(int? blockId) =>
      _voiceService.isReminderActive(blockId);

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _voiceService.init();
      unawaited(_notificationService.initAndRequestPermissions());

      if (_repository.currentUser == null) {
        // Each phone/simulator signs in with its own distinct member account by default:
        // Android device -> Neslihan (esim@familyapp.app)
        // iOS device -> İlker (ilker@familyapp.app)
        final isAndroidDevice =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        final defaultEmail = isAndroidDevice
            ? SupabaseConfig.defaultWifeEmail
            : SupabaseConfig.defaultHusbandEmail;
        await _repository.signInCustom(
          defaultEmail,
          SupabaseConfig.defaultCouplePassword,
        );
      }

      _syncCurrentUserMetadata();
      _isAuthenticated = _repository.currentUser != null;

      if (_isAuthenticated) {
        await _loadAuthenticatedWorkspace();
      }
    } catch (e) {
      _errorMessage = 'Veri bağlantısı kurulurken hata: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAuthenticatedWorkspace() async {
    _familyProfile = await _repository.loadFamilyProfile();
    _connectedMemberNames = await _repository.loadConnectedMemberNames(
      _familyProfile.id,
    );
    _prayerTimes = await _repository.loadLivePrayerTimes(
      _familyProfile.city,
      _selectedDate,
    );
    await _reloadBlocksAndSessions(alignPrayerTimes: true);
    _setupRealtimeSubscription();
    _startMinuteClockWatcher();
  }

  void _syncCurrentUserMetadata() {
    final user = _repository.currentUser;
    if (user != null) {
      _activeUserEmail = user.email ?? '';
      final isSecondMember =
          _activeUserEmail.toLowerCase().contains('esim') ||
          _activeUserEmail.toLowerCase().contains('neslihan') ||
          user.userMetadata?['role'] == 'wife';
      _memberRoleKey = isSecondMember ? 'wife' : 'husband';

      final metaName = user.userMetadata?['display_name']?.toString();
      if (metaName != null &&
          metaName.trim().isNotEmpty &&
          metaName.trim() != 'Eşim') {
        _activeDisplayName = metaName.trim();
      } else {
        _activeDisplayName = isSecondMember ? 'Neslihan' : 'İlker';
      }
    }
  }

  Future<void> signOut() async {
    _realtimeChannel?.unsubscribe();
    _minuteScheduleWatcher?.cancel();
    await _voiceService.stopAll();
    await _repository.signOut();
    _isAuthenticated = false;
    _blocks = [];
    _medicationReminders = [];
    _waterTrackers = [];
    notifyListeners();
  }

  Future<String?> registerOrLoginUser({
    required bool isSignUp,
    required String displayName,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cleanEmail = email.trim().toLowerCase();
      final inferredRole =
          (cleanEmail.contains('esim') || cleanEmail.contains('neslihan'))
              ? 'wife'
              : 'husband';

      if (isSignUp) {
        await _repository.registerNewMember(
          displayName: displayName,
          email: cleanEmail,
          password: password,
          roleLabel: inferredRole,
          inviteCode: inviteCode,
        );
      } else {
        await _repository.signInCustom(cleanEmail, password);
      }

      _syncCurrentUserMetadata();
      if (isSignUp && displayName.trim().isNotEmpty) {
        _activeDisplayName = displayName.trim();
      }
      _isAuthenticated = _repository.currentUser != null;

      if (_isAuthenticated) {
        await _loadAuthenticatedWorkspace();
        await _notificationService.sendDeviceNotification(
          id: 7001,
          title: 'Hoş Geldin, $_activeDisplayName',
          body:
              'Kişisel ajandanız ve ortak planlarınız güvenli şekilde senkronize edildi.',
        );
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadBlocksAndSessions({bool alignPrayerTimes = false}) async {
    if (!_isAuthenticated) return;
    final loadedBlocks = await _repository.loadScheduleBlocks(
      familyId: _familyProfile.id,
      planDate: formattedSelectedDate,
    );
    if (alignPrayerTimes) {
      _blocks = await _repository.syncPrayerAnchoredBlocks(
        blocks: loadedBlocks,
        prayerTimes: _prayerTimes,
      );
    } else {
      _blocks = loadedBlocks;
    }
    _focusSessions = await _repository.loadFocusSessions(_familyProfile.id);
    _medicationReminders = await _repository.loadMedicationReminders(
      _familyProfile.id,
    );
    _waterTrackers = await _repository.loadWaterTrackers(_familyProfile.id);
    _partnerInvitations = await _repository.loadPartnerInvitations(
      _familyProfile.id,
    );
    _connectedMemberNames = await _repository.loadConnectedMemberNames(
      _familyProfile.id,
    );
    notifyListeners();
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _repository.subscribeToRealtime(
      familyId: _familyProfile.id,
      onChanged: () {
        _reloadBlocksAndSessions(alignPrayerTimes: false);
      },
    );
  }

  void _startMinuteClockWatcher() {
    _minuteScheduleWatcher?.cancel();
    _minuteScheduleWatcher = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _checkTimeTriggers(),
    );
  }

  void _checkTimeTriggers() {
    if (!_isAuthenticated) return;
    final now = DateTime.now();
    final currentHhmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final block in filteredBlocks) {
      if (block.voiceReminderEnabled && block.status == 'planned') {
        final parts = block.startTime.split(':');
        if (parts.length >= 2) {
          final startMins =
              (int.tryParse(parts[0]) ?? 0) * 60 +
              (int.tryParse(parts[1]) ?? 0);
          final nowMins = now.hour * 60 + now.minute;
          final diff = startMins - nowMins;
          if (diff == block.remindBeforeMinutes &&
              !_voiceService.isReminderActive(block.id)) {
            triggerVoiceReminderNow(block);
          }
        }
      }

      if (block.phoneLockEnabled &&
          block.startTime == currentHhmm &&
          !_isPhoneLockShieldActive) {
        activatePhoneLockdownShield(
          title: '${block.title} (${block.startTime} - ${block.endTime})',
        );
      }
    }

    for (final med in _medicationReminders) {
      if (!med.takenToday && med.reminderTime == currentHhmm) {
        sendMedicationDeviceNotification(med);
      }
    }
  }

  Future<bool> requestDeviceNotificationPermissions() async {
    final granted = await _notificationService.requestPermissionsExplicitly();
    notifyListeners();
    return granted;
  }

  Future<void> createPartnerInvite({
    required String inviteeLabel,
    required String relationshipType,
    String? inviteeEmail,
  }) async {
    try {
      final code =
          '${_familyProfile.inviteCode}-${DateTime.now().second.toString().padLeft(2, '0')}';
      final created = await _repository.addPartnerInvitation(
        PartnerInvitation(
          familyId: _familyProfile.id,
          inviterName: _activeDisplayName,
          inviteeLabel: inviteeLabel.trim(),
          inviteeEmail: inviteeEmail?.trim(),
          relationshipType: relationshipType,
          inviteCode: code,
          status: 'pending',
          allowSharedPlans: true,
        ),
      );
      _partnerInvitations.insert(0, created);
      await _notificationService.sendDeviceNotification(
        id: 7002,
        title: 'Ortak Plan Davet Kodu: $code',
        body:
            '$inviteeLabel ile yalnızca ortak seçilen planları paylaşmak üzere davet oluşturuldu.',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Davet oluşturma hatası: $e');
    }
  }

  void setTimelineFilter(String filter) {
    _timelineFilter = filter;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    _prayerTimes = await _repository.loadLivePrayerTimes(
      _familyProfile.city,
      _selectedDate,
    );
    await _reloadBlocksAndSessions(alignPrayerTimes: true);
  }

  Future<void> syncAllWithLivePrayerTimes() async {
    _prayerTimes = await _repository.loadLivePrayerTimes(
      _familyProfile.city,
      _selectedDate,
    );
    _blocks = await _repository.syncPrayerAnchoredBlocks(
      blocks: _blocks,
      prayerTimes: _prayerTimes,
    );
    notifyListeners();
  }

  Future<void> checkInToBlock(ScheduleBlock block) async {
    if (block.id != null) {
      _voiceService.cancelReminder(block.id!);
    }
    _lastSpokenReminder = null;

    final updated = block.copyWith(
      status: 'checked_in',
      checkedInAt: DateTime.now(),
    );
    await saveOrCreateBlock(updated);
    await _notificationService.sendDeviceNotification(
      id: (block.id ?? 100) + 1000,
      title: 'Katılım Onaylandı: ${block.title}',
      body:
          'Sesli tekrarlayan hatırlatıcı durduruldu. İyi çalışmalar, $_activeDisplayName!',
    );
  }

  Future<void> toggleChecklistItem(ScheduleBlock block, String itemId) async {
    final updatedItems = block.checklistItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(done: !item.done);
      }
      return item;
    }).toList();

    final updatedBlock = block.copyWith(checklistItems: updatedItems);
    await saveOrCreateBlock(updatedBlock);
  }

  Future<void> completeBlockWithSummary({
    required ScheduleBlock block,
    required String completionNotes,
    List<ChecklistItem>? updatedChecklist,
  }) async {
    if (block.id != null) {
      _voiceService.cancelReminder(block.id!);
    }
    final updated = block.copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
      completionNotes: completionNotes.trim(),
      checklistItems: updatedChecklist ?? block.checklistItems,
    );
    await saveOrCreateBlock(updated);
  }

  Future<void> skipBlockWithReason({
    required ScheduleBlock block,
    required String skipReason,
  }) async {
    if (block.id != null) {
      _voiceService.cancelReminder(block.id!);
    }
    final updated = block.copyWith(
      status: 'skipped',
      skipReason: skipReason.trim().isEmpty
          ? 'Bugün katılınamadı / ertelendi'
          : skipReason.trim(),
    );
    await saveOrCreateBlock(updated);
  }

  void triggerVoiceReminderNow(ScheduleBlock block) {
    _notificationService.sendDeviceNotification(
      id: (block.id ?? 1) + 2000,
      title: 'Plan Hatırlatıcı: ${block.title}',
      body:
          '${block.startTime} - ${block.endTime} (${block.remindBeforeMinutes} dk kala hatırlatma • ${block.repeatCount}x tekrar)',
    );
    _voiceService.startRepeatingReminder(
      block: block,
      onSpoken: (msg) {
        _lastSpokenReminder = msg;
        notifyListeners();
      },
    );
  }

  Future<void> stopAllVoiceReminders() async {
    await _voiceService.stopAll();
    _lastSpokenReminder = null;
    notifyListeners();
  }

  // ===========================================================================
  // MEDICATION & WATER TRACKER ACTIONS + OS NOTIFICATIONS
  // ===========================================================================

  Future<void> toggleMedicationTaken(MedicationReminder reminder) async {
    try {
      final updated = await _repository.toggleMedicationTaken(
        reminder,
        formattedSelectedDate,
      );
      final idx = _medicationReminders.indexWhere((m) => m.id == updated.id);
      if (idx >= 0) {
        _medicationReminders[idx] = updated;
      }
      if (updated.takenToday) {
        await _notificationService.sendDeviceNotification(
          id: (updated.id ?? 10) + 4000,
          title: 'İlaç Alındı: ${updated.medicationName}',
          body:
              '${updated.dosage} (${updated.mealRelation}) içildi olarak işaretlendi.',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('İlaç durumu güncelleme hatası: $e');
    }
  }

  Future<void> addMedicationReminder(MedicationReminder reminder) async {
    try {
      final created = await _repository.addMedicationReminder(reminder);
      _medicationReminders.add(created);
      _medicationReminders.sort(
        (a, b) => a.reminderTime.compareTo(b.reminderTime),
      );
      await _notificationService.sendDeviceNotification(
        id: (created.id ?? 20) + 4100,
        title: 'İlaç Hatırlatıcı Kuruldu: ${created.medicationName}',
        body:
            'Her gün saat ${created.reminderTime} (${created.mealRelation}) cihaz bildirimi gönderilecek.',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('İlaç ekleme hatası: $e');
    }
  }

  Future<void> deleteMedicationReminder(int id) async {
    try {
      await _repository.removeMedicationReminder(id);
      _medicationReminders.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('İlaç silme hatası: $e');
    }
  }

  Future<void> sendMedicationDeviceNotification(
    MedicationReminder reminder,
  ) async {
    final msg =
        '${reminder.medicationName} (${reminder.dosage}) alma vakti geldi. ${reminder.mealRelation} alınız.';
    _lastSpokenReminder = msg;
    notifyListeners();
    await _notificationService.sendDeviceNotification(
      id: (reminder.id ?? 30) + 4500,
      title: 'İlaç Vakti: ${reminder.medicationName}',
      body: msg,
    );
  }

  Future<void> addWaterIntake(int deltaMl) async {
    try {
      final current = activeWaterTracker;
      final nextMl = (current.currentIntakeMl + deltaMl).clamp(0, 10000);
      final updated = await _repository.updateWaterIntake(
        tracker: current,
        newIntakeMl: nextMl,
      );
      if (_waterTrackers.isEmpty) {
        _waterTrackers = [updated];
      } else {
        _waterTrackers[0] = updated;
      }
      if (deltaMl > 0) {
        await _notificationService.sendDeviceNotification(
          id: 5100,
          title: 'Su Takibi Güncellendi (+$deltaMl ml)',
          body:
              'Günlük su tüketiminiz: ${updated.currentIntakeMl} / ${updated.dailyGoalMl} ml (%${(updated.progressRatio * 100).round()}).',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Su takibi güncelleme hatası: $e');
    }
  }

  Future<void> triggerWaterDeviceNotificationNow() async {
    final tracker = activeWaterTracker;
    final remaining = (tracker.dailyGoalMl - tracker.currentIntakeMl).clamp(
      0,
      10000,
    );
    final msg = remaining > 0
        ? 'Su içme vakti! 1 bardak (${tracker.cupSizeMl} ml) su için. Hedefe kalan: $remaining ml.'
        : 'Tebrikler! Günlük ${tracker.dailyGoalMl} ml su hedefinizi tamamladınız.';
    _lastSpokenReminder = msg;
    notifyListeners();
    await _notificationService.sendDeviceNotification(
      id: 5200,
      title:
          'Su Hatırlatıcı (${tracker.currentIntakeMl}/${tracker.dailyGoalMl} ml)',
      body: msg,
    );
  }

  Future<void> saveOrCreateBlock(ScheduleBlock block) async {
    try {
      final saved = await _repository.saveBlock(block);
      final idx = _blocks.indexWhere((b) => b.id == saved.id);
      if (idx >= 0) {
        _blocks[idx] = saved;
      } else {
        _blocks.add(saved);
      }
      _blocks.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();
    } catch (e) {
      debugPrint('Plan kaydetme hatası: $e');
    }
  }

  Future<void> deleteBlock(int blockId) async {
    try {
      _voiceService.cancelReminder(blockId);
      await _repository.removeBlock(blockId);
      _blocks.removeWhere((b) => b.id == blockId);
      notifyListeners();
    } catch (e) {
      debugPrint('Plan silme hatası: $e');
    }
  }

  Future<void> addFocusSession(FocusSession session) async {
    final created = await _repository.addFocusSession(session);
    _focusSessions.add(created);
    notifyListeners();
  }

  Future<void> toggleFocusSession(FocusSession session) async {
    final updated = await _repository.toggleFocusSession(session);
    final idx = _focusSessions.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      _focusSessions[idx] = updated;
      notifyListeners();
    }
  }

  void activatePhoneLockdownShield({String? title}) {
    _activeLockdownReason =
        title ?? 'Odak & Kısıtlama Modu (Sadece Aramalar Açık)';
    _isPhoneLockShieldActive = true;
    notifyListeners();
  }

  void deactivatePhoneLockdownShield() {
    _isPhoneLockShieldActive = false;
    notifyListeners();
  }

  Future<void> updateFamilySettings({
    required String city,
    required String wakeUpTime,
    required String sleepTime,
  }) async {
    _familyProfile = await _repository.saveFamilySettings(
      familyId: _familyProfile.id,
      city: city,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
    );
    await syncAllWithLivePrayerTimes();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _minuteScheduleWatcher?.cancel();
    _voiceService.stopAll();
    super.dispose();
  }
}
