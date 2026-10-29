import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/planner_repository.dart';
import '../../data/services/voice_reminder_service.dart';
import '../../domain/models/family_models.dart';

class PlannerViewModel extends ChangeNotifier {
  final PlannerRepository _repository;
  final VoiceReminderService _voiceService;

  PlannerViewModel({required this._repository, required this._voiceService});

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _activeUserRole = 'husband'; // 'husband' (İlker) | 'wife' (Eşim)
  String get activeUserRole => _activeUserRole;

  String _timelineFilter = 'all'; // 'all' | 'husband' | 'wife' | 'shared'
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

  bool _isPhoneLockShieldActive = false;
  bool get isPhoneLockShieldActive => _isPhoneLockShieldActive;

  String _activeLockdownReason =
      'Odak & Telefon Kısıtlama Modu (Sadece Aramalar)';
  String get activeLockdownReason => _activeLockdownReason;

  String? _lastSpokenReminder;
  String? get lastSpokenReminder => _lastSpokenReminder;

  RealtimeChannel? _realtimeChannel;
  Timer? _minuteScheduleWatcher;

  String get formattedSelectedDate =>
      _selectedDate.toIso8601String().substring(0, 10);

  List<ScheduleBlock> get filteredBlocks {
    final weekday = _selectedDate.weekday; // 1 = Pazartesi .. 7 = Pazar
    final dayBlocks = _blocks.where((b) {
      if (b.isRecurringDaily) {
        return b.recurrenceDays.isEmpty || b.recurrenceDays.contains(weekday);
      }
      return b.planDate == formattedSelectedDate;
    }).toList();

    if (_timelineFilter == 'all') return dayBlocks;
    if (_timelineFilter == 'husband') {
      return dayBlocks
          .where((b) => b.ownerRole == 'husband' || b.ownerRole == 'shared')
          .toList();
    }
    if (_timelineFilter == 'wife') {
      return dayBlocks
          .where((b) => b.ownerRole == 'wife' || b.ownerRole == 'shared')
          .toList();
    }
    return dayBlocks.where((b) => b.ownerRole == _timelineFilter).toList();
  }

  List<ScheduleBlock> get husbandBlocks => _blocks
      .where((b) => b.ownerRole == 'husband' || b.ownerRole == 'shared')
      .toList();

  List<ScheduleBlock> get wifeBlocks => _blocks
      .where((b) => b.ownerRole == 'wife' || b.ownerRole == 'shared')
      .toList();

  int get completedCount =>
      _blocks.where((b) => b.status == 'completed').length;

  int get checkedInCount =>
      _blocks.where((b) => b.status == 'checked_in').length;

  int get skippedCount => _blocks.where((b) => b.status == 'skipped').length;

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
      await _repository.ensureSignedInAsRole(_activeUserRole);
      _familyProfile = await _repository.loadFamilyProfile();
      _prayerTimes = await _repository.loadLivePrayerTimes(
        _familyProfile.city,
        _selectedDate,
      );
      await _reloadBlocksAndSessions(alignPrayerTimes: true);
      _setupRealtimeSubscription();
      _startMinuteClockWatcher();
    } catch (e) {
      _errorMessage = 'Veri bağlantısı kurulurken hata: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadBlocksAndSessions({bool alignPrayerTimes = false}) async {
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
    final now = DateTime.now();
    final currentHhmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final block in filteredBlocks) {
      // Check if reminder time matches current minute
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

      // Check if a block with phone_lock_enabled is starting right now
      if (block.phoneLockEnabled &&
          block.startTime == currentHhmm &&
          !_isPhoneLockShieldActive) {
        activatePhoneLockdownShield(
          title: '${block.title} (${block.startTime} - ${block.endTime})',
        );
      }
    }
  }

  Future<void> switchActivePersonRole(String role) async {
    if (_activeUserRole == role) return;
    _activeUserRole = role;
    notifyListeners();
    try {
      await _repository.ensureSignedInAsRole(role);
      await _reloadBlocksAndSessions();
    } catch (e) {
      debugPrint('Kullanıcı geçiş uyarısı: $e');
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

  /// User taps "Derse Geldim / Başladım": cancels repeating voice alarms and marks checked_in.
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
  }

  /// User toggles a sub-task checkbox ("tık attığı yer").
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

  /// User completes the block and writes what they accomplished before the next task.
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

  /// User skips the lesson/task ("bugün derse gitmeyip atladığında bunu takip edebilir olmalı").
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
        title ?? 'Aile Odak & Kısıtlama Modu (Sadece Aramalar Açık)';
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
