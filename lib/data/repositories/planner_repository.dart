import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/family_models.dart';
import '../services/prayer_time_service.dart';
import '../services/supabase_family_service.dart';

class PlannerRepository {
  final SupabaseFamilyService _supabaseService;
  final PrayerTimeService _prayerService;

  PlannerRepository({
    required this._supabaseService,
    required this._prayerService,
  });

  User? get currentUser => _supabaseService.currentUser;

  Future<void> signOut() async {
    await _supabaseService.signOut();
  }

  Future<void> signInCustom(String email, String password) async {
    await _supabaseService.signInWithCredentials(
      email: email,
      password: password,
    );
  }

  Future<String> registerNewMember({
    required String displayName,
    required String email,
    required String password,
    required String roleLabel,
    String? inviteCode,
  }) {
    return _supabaseService.signUpNewMember(
      displayName: displayName,
      email: email,
      password: password,
      roleLabel: roleLabel,
      inviteCode: inviteCode,
    );
  }

  Future<List<String>> loadConnectedMemberNames(int familyId) {
    return _supabaseService.fetchConnectedMemberNames(familyId);
  }

  Future<List<MemberAccountProfile>> loadFamilyMemberProfiles(int familyId) {
    return _supabaseService.fetchFamilyMemberProfiles(familyId);
  }

  Future<void> updateFamilyConnectionStatus({
    required int familyId,
    required String connectionStatus,
  }) {
    return _supabaseService.updateFamilyConnectionStatus(
      familyId: familyId,
      connectionStatus: connectionStatus,
    );
  }

  Future<FamilyProfile> loadFamilyProfile() {
    return _supabaseService.fetchPrimaryFamily();
  }

  Future<FamilyProfile> saveFamilySettings({
    required int familyId,
    required String city,
    required String wakeUpTime,
    required String sleepTime,
  }) {
    return _supabaseService.updateFamilySettings(
      familyId: familyId,
      city: city,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
    );
  }

  Future<PrayerTimesDay> loadLivePrayerTimes(String city, DateTime date) async {
    try {
      return await _prayerService.fetchLivePrayerTimes(city: city, date: date);
    } catch (e) {
      debugPrint('Namaz vakti API yedek moda geçti: $e');
      return PrayerTimesDay.fallback(city: city);
    }
  }

  Future<List<ScheduleBlock>> loadScheduleBlocks({
    required int familyId,
    required String planDate,
  }) {
    return _supabaseService.fetchScheduleBlocks(
      familyId: familyId,
      planDate: planDate,
    );
  }

  /// Automatically aligns prayer-anchored blocks (e.g. Sabah Namazı, Namaz Sonrası Servis)
  /// with today's live Diyanet prayer times and persists them to Supabase.
  Future<List<ScheduleBlock>> syncPrayerAnchoredBlocks({
    required List<ScheduleBlock> blocks,
    required PrayerTimesDay prayerTimes,
  }) async {
    final List<ScheduleBlock> result = [];
    for (final block in blocks) {
      if (!block.isPrayerAnchored || block.prayerName == null) {
        result.add(block);
        continue;
      }

      final basePrayerTime = prayerTimes.timeForPrayer(block.prayerName);
      if (basePrayerTime == null) {
        result.add(block);
        continue;
      }

      final duration = PrayerTimeService.durationMinutes(
        block.startTime,
        block.endTime,
      );
      final newStart = PrayerTimeService.addMinutesToTime(
        basePrayerTime,
        block.prayerOffsetMinutes,
      );
      final newEnd = PrayerTimeService.addMinutesToTime(newStart, duration);

      if (newStart != block.startTime || newEnd != block.endTime) {
        final updatedBlock = block.copyWith(
          startTime: newStart,
          endTime: newEnd,
        );
        try {
          final saved = await _supabaseService.updateScheduleBlock(
            updatedBlock,
          );
          result.add(saved);
        } catch (_) {
          result.add(updatedBlock);
        }
      } else {
        result.add(block);
      }
    }

    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  Future<ScheduleBlock> saveBlock(ScheduleBlock block) {
    return _supabaseService.updateScheduleBlock(block);
  }

  Future<void> removeBlock(int blockId) {
    return _supabaseService.deleteScheduleBlock(blockId);
  }

  Future<List<FocusSession>> loadFocusSessions(int familyId) {
    return _supabaseService.fetchFocusSessions(familyId);
  }

  Future<FocusSession> addFocusSession(FocusSession session) {
    return _supabaseService.createFocusSession(session);
  }

  Future<FocusSession> toggleFocusSession(FocusSession session) {
    return _supabaseService.toggleFocusSession(session);
  }

  Future<void> removeFocusSession(int id) {
    return _supabaseService.deleteFocusSession(id);
  }

  // Medication Reminders
  Future<List<MedicationReminder>> loadMedicationReminders(int familyId) {
    return _supabaseService.fetchMedicationReminders(familyId);
  }

  Future<MedicationReminder> addMedicationReminder(
    MedicationReminder reminder,
  ) {
    return _supabaseService.createMedicationReminder(reminder);
  }

  Future<MedicationReminder> toggleMedicationTaken(
    MedicationReminder reminder,
    String todayIso,
  ) {
    return _supabaseService.toggleMedicationTaken(reminder, todayIso);
  }

  Future<void> removeMedicationReminder(int id) {
    return _supabaseService.deleteMedicationReminder(id);
  }

  // Water Trackers
  Future<List<WaterTracker>> loadWaterTrackers(int familyId) {
    return _supabaseService.fetchWaterTrackers(familyId);
  }

  Future<WaterTracker> updateWaterIntake({
    required WaterTracker tracker,
    required int newIntakeMl,
    int? newGoalMl,
  }) {
    return _supabaseService.updateWaterIntake(
      tracker: tracker,
      newIntakeMl: newIntakeMl,
      newGoalMl: newGoalMl,
    );
  }

  // Partner Invitations (@username Ecosystem)
  Future<List<PartnerInvitation>> loadPartnerInvitations(int familyId) {
    return _supabaseService.fetchPartnerInvitations(familyId);
  }

  Future<PartnerInvitation> addPartnerInvitation(PartnerInvitation invitation) {
    return _supabaseService.createPartnerInvitation(invitation);
  }

  Future<PartnerInvitation> updatePartnerInvitation({
    required int id,
    required String status,
    required bool sharingPaused,
  }) {
    return _supabaseService.updatePartnerInvitation(
      id: id,
      status: status,
      sharingPaused: sharingPaused,
    );
  }

  Future<void> removePartnerInvitation(int id) {
    return _supabaseService.deletePartnerInvitation(id);
  }

  // Shared Chores, Shopping & Partner Notes (Cupla / TimeTree Benchmark)
  Future<List<SharedChoreNote>> loadSharedChoresAndNotes(int familyId) {
    return _supabaseService.fetchSharedChoresAndNotes(familyId);
  }

  Future<SharedChoreNote> addSharedChoreOrNote(SharedChoreNote item) {
    return _supabaseService.createSharedChoreOrNote(item);
  }

  Future<SharedChoreNote> toggleSharedChoreOrNote(SharedChoreNote item) {
    return _supabaseService.toggleSharedChoreOrNote(item);
  }

  Future<void> removeSharedChoreOrNote(int id) {
    return _supabaseService.deleteSharedChoreOrNote(id);
  }

  // Daily 5-Prayer Worship Tracker (MyWaqt / Pillars Benchmark)
  Future<List<String>> loadCompletedPrayers({
    required int familyId,
    required String username,
    required String prayerDate,
  }) {
    return _supabaseService.fetchCompletedPrayers(
      familyId: familyId,
      username: username,
      prayerDate: prayerDate,
    );
  }

  Future<List<String>> saveCompletedPrayers({
    required int familyId,
    required String username,
    required String prayerDate,
    required List<String> completedPrayers,
  }) {
    return _supabaseService.saveCompletedPrayers(
      familyId: familyId,
      username: username,
      prayerDate: prayerDate,
      completedPrayers: completedPrayers,
    );
  }

  Future<void> purgePersonalAccountData(int familyId) {
    return _supabaseService.purgePersonalAccountData(familyId);
  }

  RealtimeChannel subscribeToRealtime({
    required int familyId,
    required VoidCallback onChanged,
  }) {
    return _supabaseService.subscribeToFamilyChanges(
      familyId: familyId,
      onDataChanged: onChanged,
    );
  }
}
