import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../data/repositories/planner_repository.dart';
import '../../data/services/daily_spiritual_service.dart';
import '../../data/services/device_notification_service.dart';
import '../../data/services/voice_reminder_service.dart';
import '../../domain/models/family_models.dart';

class PlannerViewModel extends ChangeNotifier {
  final PlannerRepository _repository;
  final VoiceReminderService _voiceService;
  final DeviceNotificationService _notificationService;
  final DailySpiritualService _spiritualService;

  PlannerViewModel({
    required this._repository,
    required this._voiceService,
    DeviceNotificationService? notificationService,
    DailySpiritualService? spiritualService,
  }) : _notificationService =
           notificationService ?? DeviceNotificationService(),
       _spiritualService = spiritualService ?? DailySpiritualService();

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

  String _activeUsername = 'ilker';
  String get activeUsername => _activeUsername;
  String get activeUsernameHandle => '@$_activeUsername';

  String _activeUserEmail = '';
  String get activeUserEmail => _activeUserEmail;

  List<String> _connectedMemberNames = const ['İlker', 'Neslihan'];
  List<String> get connectedMemberNames => _connectedMemberNames;

  List<MemberAccountProfile> _memberProfiles = [];
  List<MemberAccountProfile> get memberProfiles => _memberProfiles;

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
  List<ScheduleBlock> get allBlocks => _blocksForSelectedDate;

  List<FocusSession> _focusSessions = [];
  List<FocusSession> get focusSessions => _focusSessions;

  List<MedicationReminder> _medicationReminders = [];
  List<MedicationReminder> get medicationReminders => _medicationReminders;

  List<WaterTracker> _waterTrackers = [];
  List<WaterTracker> get waterTrackers => _waterTrackers;

  List<PartnerInvitation> _partnerInvitations = [];
  List<PartnerInvitation> get partnerInvitations => _partnerInvitations;

  List<SharedChoreNote> _sharedChoresAndNotes = [];
  List<SharedChoreNote> get sharedChoresAndNotes => _sharedChoresAndNotes;

  List<String> _completedPrayersToday = [];
  List<String> get completedPrayersToday => _completedPrayersToday;

  bool isPrayerCompletedToday(String prayerKey) =>
      _completedPrayersToday.contains(prayerKey);

  bool _isPhoneLockShieldActive = false;
  bool get isPhoneLockShieldActive => _isPhoneLockShieldActive;

  String _activeLockdownReason =
      'Odak & Telefon Kısıtlama Modu (Sadece Aramalar)';
  String get activeLockdownReason => _activeLockdownReason;

  String? _lastSpokenReminder;
  String? get lastSpokenReminder => _lastSpokenReminder;

  ActiveAlarmSession? _activeAlarmSession;
  ActiveAlarmSession? get activeAlarmSession => _activeAlarmSession;

  String? _snoozedAlarmSummary;
  String? get snoozedAlarmSummary => _snoozedAlarmSummary;
  Timer? _snoozeWakeTimer;

  DailySpiritualContent _dailySpiritual = const DailySpiritualContent(
    dateKey: '2026-10-30',
    hadithText:
        'Ameller niyetlere göredir. Herkese ancak niyet ettiği şey vardır.',
    hadithSource: 'Sahîh-i Buhârî, Bed\'ü\'l-Vahy 1',
    hadithNumber: 'Hadis #1',
    duaArabic:
        'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    duaTurkish:
        'Rabbimiz! Bize eşlerimizden ve çocuklarımızdan gözümüzün aydınlığı olacak insanlar ihsan et ve bizi, Allah\'a karşı gelmekten sakınanlara önder yap.',
    duaSource: 'Furkan Suresi, 74. Ayet • Aile & Eş Duası',
    morningEveningZikir:
        'Sabah/Akşam Zikri: "Hasbiyallâhu lâ ilâhe illâ hû, aleyhi tevekkeltü ve hüve Rabbü\'l-arşi\'l-azîm." (Tevbe, 129)',
    isLiveFromOpenSource: true,
  );
  DailySpiritualContent get dailySpiritual => _dailySpiritual;

  String _activeWidgetStyle = 'hadith_dua';
  String get activeWidgetStyle => _activeWidgetStyle;

  String get selectedAlarmToneId => _voiceService.selectedToneId;
  bool get voiceTitleAfterChime => _voiceService.voiceTitleAfterChime;

  // Dynamic Prayer-Time Adhan (Ezan Vakti Ezan Okuma) State
  bool _adhanEnabled = true;
  bool get adhanEnabled => _adhanEnabled;

  final Set<String> _adhanEnabledPrayers = {
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  };
  Set<String> get adhanEnabledPrayers => _adhanEnabledPrayers;

  bool isAdhanEnabledForPrayer(String prayerKey) =>
      _adhanEnabled && _adhanEnabledPrayers.contains(prayerKey);

  String get selectedAdhanStyle => _voiceService.selectedAdhanStyle;
  String get selectedAdhanStyleLabel =>
      VoiceReminderService.adhanStyleLabels[selectedAdhanStyle] ??
      'Mekke • Hicaz Ezan';
  bool get isAdhanPlaying => _voiceService.isAdhanPlaying;

  bool get deviceNotificationsGranted => _notificationService.permissionGranted;

  RealtimeChannel? _realtimeChannel;
  Timer? _minuteScheduleWatcher;
  final Set<int> _autoTriggeredBlockIds = {};
  final Set<String> _autoTriggeredPrayerAdhans = {};

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

  List<ScheduleBlock> get _blocksForSelectedDate {
    final weekday = _selectedDate.weekday;
    return _blocks.where((b) {
      if (b.isRecurringDaily) {
        return b.recurrenceDays.isEmpty || b.recurrenceDays.contains(weekday);
      }
      return b.planDate == formattedSelectedDate;
    }).toList();
  }

  /// Blocks already filtered at DB RLS level so ONLY this user's personal blocks
  /// and 'shared' blocks exist in `_blocks`.
  List<ScheduleBlock> get filteredBlocks {
    final dayBlocks = _blocksForSelectedDate;

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
      _blocksForSelectedDate.where((b) => b.ownerRole != 'shared').toList();

  /// Shared plans visible to both connected members
  List<ScheduleBlock> get sharedBlocksOnly =>
      _blocksForSelectedDate.where((b) => b.ownerRole == 'shared').toList();

  /// Other connected members in the shared group (excluding current user)
  List<String> get linkedPartnerNames {
    final others = _connectedMemberNames
        .where((n) => n.toLowerCase() != _activeDisplayName.toLowerCase())
        .toList();
    return others;
  }

  /// Active partner handle (e.g. '@neslihan' or '@ilker')
  String get primaryPartnerHandle {
    final otherProfile = _memberProfiles
        .where((m) => m.username.toLowerCase() != _activeUsername.toLowerCase())
        .firstOrNull;
    if (otherProfile != null) {
      return otherProfile.formattedHandle;
    }
    return _memberRoleKey == 'wife' ? '@ilker' : '@neslihan';
  }

  bool get isPartnerConnectionActive {
    final myProfile = _memberProfiles
        .where((m) => m.username.toLowerCase() == _activeUsername.toLowerCase())
        .firstOrNull;
    if (myProfile != null) {
      return myProfile.connectionStatus == 'connected';
    }
    return true;
  }

  bool get isPartnerSharingPaused {
    final myProfile = _memberProfiles
        .where((m) => m.username.toLowerCase() == _activeUsername.toLowerCase())
        .firstOrNull;
    return myProfile?.connectionStatus == 'paused';
  }

  int get completedCount =>
      allBlocks.where((b) => b.status == 'completed').length;

  int get checkedInCount =>
      allBlocks.where((b) => b.status == 'checked_in').length;

  int get skippedCount => allBlocks.where((b) => b.status == 'skipped').length;

  int get takenMedicationCount =>
      _medicationReminders.where((m) => m.takenToday).length;

  double get completionRate {
    if (allBlocks.isEmpty) return 0;
    final doneOrActive = completedCount + checkedInCount;
    return (doneOrActive / allBlocks.length) * 100;
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
    unawaited(_loadDailySpiritualAndSyncWidget());
    _setupRealtimeSubscription();
    _startMinuteClockWatcher();
  }

  Future<void> _loadDailySpiritualAndSyncWidget({
    bool nextRotation = false,
  }) async {
    try {
      _dailySpiritual = await _spiritualService.fetchDailySpiritual(
        nextRotation: nextRotation,
      );
      notifyListeners();
      await syncPhoneHomeScreenWidget(requestPin: false);
    } catch (e) {
      debugPrint('Günlük hadis/dua yükleme bilgi: $e');
    }
  }

  Future<void> refreshDailySpiritualFromOpenSource() async {
    await _loadDailySpiritualAndSyncWidget(nextRotation: true);
  }

  Future<bool> syncPhoneHomeScreenWidget({
    String? styleOverride,
    bool requestPin = false,
  }) async {
    if (styleOverride != null) {
      _activeWidgetStyle = styleOverride;
      notifyListeners();
    }
    final nextBlock = filteredBlocks
        .where((b) => b.status == 'planned')
        .firstOrNull;
    final nextSummary = nextBlock != null
        ? 'Sıradaki: ${nextBlock.startTime} ${nextBlock.title}'
        : 'Tüm planlar tamamlandı';

    final ok = await _spiritualService.syncToPhoneHomeScreenWidget(
      content: _dailySpiritual,
      prayerTimes: _prayerTimes,
      nextPlanSummary: nextSummary,
      widgetStyle: _activeWidgetStyle,
      requestPinOnAndroid: requestPin,
    );
    if (requestPin) {
      await _notificationService.sendDeviceNotification(
        id: 8801,
        title: 'Günün Hadisi & Duası Widget Güncellendi',
        body: _dailySpiritual.hadithText,
      );
    }
    return ok;
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

      if (isSecondMember) {
        _activeUsername = 'neslihan';
      } else if (_activeUserEmail.toLowerCase().startsWith('ilker@')) {
        _activeUsername = 'ilker';
      } else {
        _activeUsername = SupabaseConfig.normalizeUsernameHandle(
          _activeUserEmail.isNotEmpty
              ? _activeUserEmail.split('@').first
              : _activeDisplayName,
        );
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

      final cleanHandle = SupabaseConfig.normalizeUsernameHandle(email);
      final internalAuthEmail =
          SupabaseConfig.usernameToInternalAuthIdentity(email);
      final inferredRole =
          (cleanHandle == 'neslihan' || cleanHandle == 'esim')
              ? 'wife'
              : 'husband';

      if (isSignUp) {
        await _repository.registerNewMember(
          displayName: displayName,
          email: internalAuthEmail,
          password: password,
          roleLabel: inferredRole,
          inviteCode: inviteCode,
        );
      } else {
        await _repository.signInCustom(internalAuthEmail, password);
      }

      _syncCurrentUserMetadata();
      if (isSignUp && displayName.trim().isNotEmpty) {
        _activeDisplayName = displayName.trim();
        _activeUsername = cleanHandle;
      }
      _isAuthenticated = _repository.currentUser != null;

      if (_isAuthenticated) {
        await _loadAuthenticatedWorkspace();
        await _notificationService.sendDeviceNotification(
          id: 7001,
          title: 'Hoş Geldin, $_activeDisplayName ($activeUsernameHandle)',
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
    _memberProfiles = await _repository.loadFamilyMemberProfiles(
      _familyProfile.id,
    );
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
    _sharedChoresAndNotes = await _repository.loadSharedChoresAndNotes(
      _familyProfile.id,
    );
    _completedPrayersToday = await _repository.loadCompletedPrayers(
      familyId: _familyProfile.id,
      username: _activeUsername,
      prayerDate: formattedSelectedDate,
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
          final blockId = block.id ?? block.title.hashCode;
          if (diff == block.remindBeforeMinutes &&
              !_autoTriggeredBlockIds.contains(blockId) &&
              !_voiceService.isReminderActive(block.id)) {
            _autoTriggeredBlockIds.add(blockId);
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

    // Dynamic Prayer-Time Adhan (Ezan Vakti Ezan Okuma) Trigger
    if (_adhanEnabled) {
      final prayerCheckMap = <String, (String, String)>{
        'Fajr': (_prayerTimes.fajr, 'Sabah'),
        'Dhuhr': (_prayerTimes.dhuhr, 'Öğle'),
        'Asr': (_prayerTimes.asr, 'İkindi'),
        'Maghrib': (_prayerTimes.maghrib, 'Akşam'),
        'Isha': (_prayerTimes.isha, 'Yatsı'),
      };
      for (final entry in prayerCheckMap.entries) {
        final prayerKey = entry.key;
        final prayerHhmm = entry.value.$1;
        final prayerLabel = entry.value.$2;
        final triggerId = '$formattedSelectedDate-$prayerKey-$prayerHhmm';
        if (_adhanEnabledPrayers.contains(prayerKey) &&
            prayerHhmm == currentHhmm &&
            !_autoTriggeredPrayerAdhans.contains(triggerId)) {
          _autoTriggeredPrayerAdhans.add(triggerId);
          triggerPrayerAdhanNow(prayerLabel: prayerLabel);
        }
      }
    }
  }

  void toggleGlobalAdhan(bool enabled) {
    _adhanEnabled = enabled;
    if (!enabled && _voiceService.isAdhanPlaying) {
      unawaited(stopAllVoiceReminders());
    } else {
      notifyListeners();
    }
  }

  void toggleAdhanForPrayer(String prayerKey) {
    if (_adhanEnabledPrayers.contains(prayerKey)) {
      if (_adhanEnabledPrayers.length > 1) {
        _adhanEnabledPrayers.remove(prayerKey);
      }
    } else {
      _adhanEnabledPrayers.add(prayerKey);
    }
    notifyListeners();
  }

  Future<void> setAdhanStyle(String styleId, {bool previewNow = false}) async {
    _voiceService.setAdhanStyle(styleId);
    notifyListeners();
    if (previewNow) {
      await triggerPrayerAdhanNow(prayerLabel: 'Vakit');
    }
  }

  Future<void> previewOrStopAdhan({String prayerLabel = 'Namaz Vakti'}) async {
    if (_voiceService.isAdhanPlaying) {
      await stopAllVoiceReminders();
      return;
    }
    await triggerPrayerAdhanNow(prayerLabel: prayerLabel);
  }

  Future<void> triggerPrayerAdhanNow({
    String prayerLabel = 'Namaz Vakti',
  }) async {
    final msg = await _voiceService.startAdhanPlayback(
      prayerName: prayerLabel,
    );
    _lastSpokenReminder = msg;
    notifyListeners();
    await _notificationService.sendDeviceNotification(
      id: 7700 + prayerLabel.hashCode.abs() % 200,
      title: '$prayerLabel Vakti Girdi • Ezan Okunuyor',
      body: '$selectedAdhanStyleLabel (${_familyProfile.city})',
    );
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
      final cleanTargetHandle = SupabaseConfig.normalizeUsernameHandle(
        inviteeEmail ?? inviteeLabel,
      );
      final code =
          '${_familyProfile.inviteCode}-${DateTime.now().second.toString().padLeft(2, '0')}';
      final created = await _repository.addPartnerInvitation(
        PartnerInvitation(
          familyId: _familyProfile.id,
          inviterName: _activeDisplayName,
          inviterUsername: _activeUsername,
          inviteeLabel: inviteeLabel.trim(),
          targetUsername: cleanTargetHandle,
          relationshipType: relationshipType,
          inviteCode: code,
          status: 'pending',
          sharingPaused: false,
          allowSharedPlans: true,
        ),
      );
      _partnerInvitations.insert(0, created);
      await _notificationService.sendDeviceNotification(
        id: 7002,
        title: 'Ortak Bağlantı İsteği Gönderildi (@$cleanTargetHandle)',
        body:
            '@$cleanTargetHandle ($inviteeLabel) kullanıcısına ortak plan daveti gönderildi (Kod: $code).',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Davet oluşturma hatası: $e');
    }
  }

  Future<void> acceptOrReconnectPartnerInvitation(
    PartnerInvitation invitation,
  ) async {
    try {
      if (invitation.id != null) {
        final updated = await _repository.updatePartnerInvitation(
          id: invitation.id!,
          status: 'accepted',
          sharingPaused: false,
        );
        final idx = _partnerInvitations.indexWhere((i) => i.id == updated.id);
        if (idx >= 0) _partnerInvitations[idx] = updated;
      }
      await _repository.updateFamilyConnectionStatus(
        familyId: _familyProfile.id,
        connectionStatus: 'connected',
      );
      await _reloadBlocksAndSessions(alignPrayerTimes: false);
    } catch (e) {
      debugPrint('Ortak bağlantı onaylama hatası: $e');
    }
  }

  Future<void> togglePausePartnerSharing(PartnerInvitation invitation) async {
    try {
      final nextPaused = !invitation.sharingPaused;
      if (invitation.id != null) {
        final updated = await _repository.updatePartnerInvitation(
          id: invitation.id!,
          status: nextPaused ? 'paused' : 'accepted',
          sharingPaused: nextPaused,
        );
        final idx = _partnerInvitations.indexWhere((i) => i.id == updated.id);
        if (idx >= 0) _partnerInvitations[idx] = updated;
      }
      await _repository.updateFamilyConnectionStatus(
        familyId: _familyProfile.id,
        connectionStatus: nextPaused ? 'paused' : 'connected',
      );
      await _reloadBlocksAndSessions(alignPrayerTimes: false);
    } catch (e) {
      debugPrint('Ortak paylaşım duraklatma hatası: $e');
    }
  }

  Future<void> removeOrUnlinkPartnerConnection(
    PartnerInvitation invitation,
  ) async {
    try {
      final wasAccepted =
          invitation.status == 'accepted' || invitation.status == 'paused';
      if (invitation.id != null) {
        await _repository.removePartnerInvitation(invitation.id!);
        _partnerInvitations.removeWhere((i) => i.id == invitation.id);
      }
      if (wasAccepted &&
          !_partnerInvitations.any((i) => i.status == 'accepted')) {
        await _repository.updateFamilyConnectionStatus(
          familyId: _familyProfile.id,
          connectionStatus: 'removed',
        );
      }
      await _reloadBlocksAndSessions(alignPrayerTimes: false);
      await _notificationService.sendDeviceNotification(
        id: 7009,
        title: 'Ortak Bağlantı Kaldırıldı (${invitation.formattedTargetHandle})',
        body:
            '${invitation.inviteeLabel} (${invitation.formattedTargetHandle}) ile ortak plan bağlantısı sonlandırıldı.',
      );
    } catch (e) {
      debugPrint('Ortak bağlantı kaldırma hatası: $e');
    }
  }

  Future<void> reconnectDefaultPartner() async {
    final targetHandle = _memberRoleKey == 'wife' ? 'ilker' : 'neslihan';
    final targetName = _memberRoleKey == 'wife' ? 'İlker' : 'Neslihan';
    await _repository.updateFamilyConnectionStatus(
      familyId: _familyProfile.id,
      connectionStatus: 'connected',
    );
    final created = await _repository.addPartnerInvitation(
      PartnerInvitation(
        familyId: _familyProfile.id,
        inviterName: _activeDisplayName,
        inviterUsername: _activeUsername,
        inviteeLabel: targetName,
        targetUsername: targetHandle,
        relationType: 'spouse',
        inviteCode: _familyProfile.inviteCode,
        status: 'accepted',
        sharingPaused: false,
      ),
    );
    _partnerInvitations.insert(0, created);
    await _reloadBlocksAndSessions(alignPrayerTimes: false);
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
    _snoozeWakeTimer?.cancel();
    _snoozedAlarmSummary = null;

    _notificationService.sendDeviceNotification(
      id: (block.id ?? 1) + 2000,
      title: 'ALARM: ${block.title} (${block.startTime})',
      body:
          '${block.remindBeforeMinutes} dk sonra başlıyor • ${block.repeatCount}x tekrarlı alarm aktif',
    );
    _voiceService.startRepeatingReminder(
      block: block,
      onSpoken: (msg) {
        _lastSpokenReminder = msg;
        notifyListeners();
      },
      onAlarmTriggered: (triggeredBlock, attempt) {
        _activeAlarmSession = ActiveAlarmSession(
          block: triggeredBlock,
          currentAttempt: attempt,
          maxAttempts: triggeredBlock.repeatCount,
          selectedToneId: _voiceService.selectedToneId,
          voiceTitleAfterChime: _voiceService.voiceTitleAfterChime,
          triggeredAt: DateTime.now(),
        );
        notifyListeners();
      },
    );
  }

  Future<void> changeAlarmTone(String toneId) async {
    _voiceService.setAlarmTone(toneId);
    final current = _activeAlarmSession;
    if (current != null) {
      _activeAlarmSession = current.copyWith(selectedToneId: toneId);
      notifyListeners();
      await _voiceService.startAlarmRinging(
        current.block,
        attempt: current.currentAttempt,
        toneOverride: toneId,
      );
    } else {
      notifyListeners();
    }
  }

  void toggleVoiceTitleOption(bool enabled) {
    _voiceService.setVoiceTitleOption(enabled);
    final current = _activeAlarmSession;
    if (current != null) {
      _activeAlarmSession = current.copyWith(voiceTitleAfterChime: enabled);
    }
    notifyListeners();
  }

  Future<void> checkInFromActiveAlarm() async {
    final current = _activeAlarmSession;
    _activeAlarmSession = null;
    _snoozeWakeTimer?.cancel();
    _snoozedAlarmSummary = null;
    await _voiceService.stopAll();
    notifyListeners();
    if (current != null) {
      await checkInToBlock(current.block);
    }
  }

  Future<void> snoozeActiveAlarm({int? customMinutes}) async {
    final current = _activeAlarmSession;
    if (current == null) return;
    final snoozeMins =
        customMinutes ?? current.block.repeatIntervalMinutes.clamp(1, 30);
    await _voiceService.stopAll();
    _activeAlarmSession = null;
    _snoozedAlarmSummary =
        '"${current.block.title}" alarmı $snoozeMins dk ertelendi (${current.currentAttempt}/${current.maxAttempts} tekrar)';
    notifyListeners();

    _snoozeWakeTimer?.cancel();
    _snoozeWakeTimer = Timer(Duration(minutes: snoozeMins), () {
      _snoozedAlarmSummary = null;
      triggerVoiceReminderNow(current.block);
    });
  }

  Future<void> dismissActiveAlarm() async {
    final currentBlockId = _activeAlarmSession?.block.id;
    if (currentBlockId != null) {
      _autoTriggeredBlockIds.add(currentBlockId);
    }
    _snoozeWakeTimer?.cancel();
    await _voiceService.stopAll();
    _activeAlarmSession = null;
    _lastSpokenReminder = null;
    notifyListeners();
  }

  Future<void> stopAllVoiceReminders() async {
    _snoozeWakeTimer?.cancel();
    _snoozedAlarmSummary = null;
    _activeAlarmSession = null;
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

  Future<void> updateWaterDailyGoal(int newGoalMl) async {
    try {
      final current = activeWaterTracker;
      final updated = await _repository.updateWaterIntake(
        tracker: current,
        newIntakeMl: current.currentIntakeMl,
        newGoalMl: newGoalMl.clamp(500, 10000),
      );
      if (_waterTrackers.isEmpty) {
        _waterTrackers = [updated];
      } else {
        _waterTrackers[0] = updated;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Su hedefi güncelleme hatası: $e');
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

  Future<void> resetBlockToPlanned(ScheduleBlock block) async {
    final updated = block.copyWith(
      status: 'planned',
      completionNotes: '',
      skipReason: '',
    );
    await saveOrCreateBlock(updated);
  }

  /// Structured Benchmark: 1-tap Replan (+15m / -15m shift when running late)
  Future<void> shiftBlockByMinutes(ScheduleBlock block, int deltaMinutes) async {
    String shiftHhMm(String hhmm) {
      final parts = hhmm.split(':');
      if (parts.length < 2) return hhmm;
      final total = ((int.tryParse(parts[0]) ?? 0) * 60 +
              (int.tryParse(parts[1]) ?? 0) +
              deltaMinutes)
          .clamp(0, 23 * 60 + 59);
      final h = (total ~/ 60).toString().padLeft(2, '0');
      final m = (total % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    final updated = block.copyWith(
      startTime: shiftHhMm(block.startTime),
      endTime: shiftHhMm(block.endTime),
    );
    await saveOrCreateBlock(updated);
  }

  /// MyWaqt / Pillars Benchmark: Daily 5-Prayer Worship Tracker
  Future<void> togglePrayerCompleted(String prayerKey) async {
    final next = List<String>.from(_completedPrayersToday);
    if (next.contains(prayerKey)) {
      next.remove(prayerKey);
    } else {
      next.add(prayerKey);
    }
    _completedPrayersToday = next;
    notifyListeners();
    try {
      _completedPrayersToday = await _repository.saveCompletedPrayers(
        familyId: _familyProfile.id,
        username: _activeUsername,
        prayerDate: formattedSelectedDate,
        completedPrayers: next,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Namaz çetelesi kaydetme hatası: $e');
    }
  }

  /// Cupla / TimeTree Benchmark: Shared Household Chores, Shopping & Partner Notes
  Future<void> addSharedChoreOrNote({
    required String title,
    required String category,
    required String assignedTo,
  }) async {
    try {
      final created = await _repository.addSharedChoreOrNote(
        SharedChoreNote(
          familyId: _familyProfile.id,
          authorUsername: _activeUsername,
          assignedTo: assignedTo,
          category: category,
          title: title.trim(),
          isDone: false,
        ),
      );
      _sharedChoresAndNotes.insert(0, created);
      await _notificationService.sendDeviceNotification(
        id: (created.id ?? 50) + 6000,
        title: 'Yeni Ortak Liste Notu (${created.categoryLabel})',
        body: '${created.formattedAuthorHandle} → ${created.assignedTo}: ${created.title}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Ortak liste ekleme hatası: $e');
    }
  }

  Future<void> toggleSharedChoreOrNote(SharedChoreNote item) async {
    try {
      final updated = await _repository.toggleSharedChoreOrNote(item);
      final idx = _sharedChoresAndNotes.indexWhere((i) => i.id == updated.id);
      if (idx >= 0) {
        _sharedChoresAndNotes[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ortak liste durum güncelleme hatası: $e');
    }
  }

  Future<void> deleteSharedChoreOrNote(int id) async {
    try {
      await _repository.removeSharedChoreOrNote(id);
      _sharedChoresAndNotes.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Ortak liste silme hatası: $e');
    }
  }

  /// Apple App Store Guideline 5.1.1(v) & KVKK/GDPR In-App Personal Data Deletion
  Future<void> purgePersonalAccountAndSignOut() async {
    _realtimeChannel?.unsubscribe();
    _minuteScheduleWatcher?.cancel();
    await _voiceService.stopAll();
    await _repository.purgePersonalAccountData(_familyProfile.id);
    _isAuthenticated = false;
    _blocks = [];
    _medicationReminders = [];
    _waterTrackers = [];
    _sharedChoresAndNotes = [];
    _completedPrayersToday = [];
    notifyListeners();
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

  Future<void> deleteFocusSession(int id) async {
    try {
      await _repository.removeFocusSession(id);
      _focusSessions.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Odak kuralı silme hatası: $e');
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
