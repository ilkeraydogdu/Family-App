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

  Future<void> ensureSignedInAsRole(String role) async {
    await _supabaseService.signInAsRole(role);
  }

  Future<void> signInCustom(String email, String password) async {
    await _supabaseService.signInWithCredentials(
      email: email,
      password: password,
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

  RealtimeChannel subscribeToRealtime({
    required int familyId,
    required VoidCallback onChanged,
  }) {
    return _supabaseService.subscribeToRealtimeChangesWrapper(
      familyId: familyId,
      onDataChanged: onChanged,
    );
  }
}

extension on SupabaseFamilyService {
  RealtimeChannel subscribeToRealtimeChangesWrapper({
    required int familyId,
    required VoidCallback onDataChanged,
  }) {
    return subscribeToFamilyChanges(
      familyId: familyId,
      onDataChanged: onDataChanged,
    );
  }
}
