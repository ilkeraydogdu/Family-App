import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/models/family_models.dart';

class SupabaseFamilyService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Signs in with the pre-seeded husband or wife account (1-tap couple switch)
  /// or custom email/password.
  Future<void> signInAsRole(String role) async {
    final email = role == 'wife'
        ? SupabaseConfig.defaultWifeEmail
        : SupabaseConfig.defaultHusbandEmail;

    if (currentUser?.email == email) return;

    await _client.auth.signInWithPassword(
      email: email,
      password: SupabaseConfig.defaultCouplePassword,
    );
  }

  Future<void> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new user account in Supabase Auth and links them to a family
  /// (either an existing family via invite code or the primary family).
  Future<String> signUpNewMember({
    required String displayName,
    required String email,
    required String password,
    required String roleLabel,
    String? inviteCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    AuthResponse authRes;
    try {
      authRes = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'display_name': displayName.trim(), 'role': roleLabel},
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        authRes = await _client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    final userId = authRes.user?.id ?? currentUser?.id;
    int targetFamilyId = 1;

    if (inviteCode != null && inviteCode.trim().isNotEmpty) {
      final familyMatch = await _client
          .from('families')
          .select('id')
          .eq('invite_code', inviteCode.trim().toUpperCase())
          .maybeSingle();
      if (familyMatch != null && familyMatch['id'] is int) {
        targetFamilyId = familyMatch['id'] as int;
      }
    }

    if (userId != null) {
      await _client.from('family_members').upsert({
        'family_id': targetFamilyId,
        'user_id': userId,
        'role': roleLabel,
        'display_name': displayName.trim(),
        'avatar_color': roleLabel == 'wife' ? '#EC4899' : '#2563EB',
      }, onConflict: 'family_id,user_id');
    }

    return cleanEmail;
  }

  Future<FamilyProfile> fetchPrimaryFamily() async {
    final response = await _client
        .from('families')
        .select()
        .order('id', ascending: true)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return const FamilyProfile(
        id: 1,
        name: 'Aydoğdu Ailesi',
        inviteCode: SupabaseConfig.defaultInviteCode,
        city: 'Istanbul',
        country: 'Turkey',
        wakeUpTime: '05:00',
        sleepTime: '23:00',
      );
    }

    return FamilyProfile.fromJson(response);
  }

  Future<FamilyProfile> updateFamilySettings({
    required int familyId,
    required String city,
    required String wakeUpTime,
    required String sleepTime,
  }) async {
    final updated = await _client
        .from('families')
        .update({
          'city': city,
          'wake_up_time': wakeUpTime,
          'sleep_time': sleepTime,
        })
        .eq('id', familyId)
        .select()
        .single();

    return FamilyProfile.fromJson(updated);
  }

  Future<List<ScheduleBlock>> fetchScheduleBlocks({
    required int familyId,
    required String planDate,
  }) async {
    final rows = await _client
        .from('schedule_blocks')
        .select()
        .eq('family_id', familyId)
        .or('plan_date.eq.$planDate,is_recurring_daily.eq.true')
        .order('start_time', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ScheduleBlock.fromJson)
        .toList();
  }

  Future<ScheduleBlock> createScheduleBlock(ScheduleBlock block) async {
    final payload = block.toInsertOrUpdateJson();
    if (currentUser != null) {
      payload['created_by'] = currentUser!.id;
    }

    final inserted = await _client
        .from('schedule_blocks')
        .insert(payload)
        .select()
        .single();

    return ScheduleBlock.fromJson(inserted);
  }

  Future<ScheduleBlock> updateScheduleBlock(ScheduleBlock block) async {
    if (block.id == null) {
      return createScheduleBlock(block);
    }

    final updated = await _client
        .from('schedule_blocks')
        .update(block.toInsertOrUpdateJson())
        .eq('id', block.id!)
        .select()
        .single();

    return ScheduleBlock.fromJson(updated);
  }

  Future<void> deleteScheduleBlock(int blockId) async {
    await _client.from('schedule_blocks').delete().eq('id', blockId);
  }

  Future<List<FocusSession>> fetchFocusSessions(int familyId) async {
    final rows = await _client
        .from('focus_sessions')
        .select()
        .eq('family_id', familyId)
        .order('start_time', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(FocusSession.fromJson)
        .toList();
  }

  Future<FocusSession> createFocusSession(FocusSession session) async {
    final inserted = await _client
        .from('focus_sessions')
        .insert(session.toJson())
        .select()
        .single();
    return FocusSession.fromJson(inserted);
  }

  Future<FocusSession> toggleFocusSession(FocusSession session) async {
    if (session.id == null) return session;
    final updated = await _client
        .from('focus_sessions')
        .update({'is_active': !session.isActive})
        .eq('id', session.id!)
        .select()
        .single();
    return FocusSession.fromJson(updated);
  }

  // ===========================================================================
  // MEDICATION REMINDERS
  // ===========================================================================

  Future<List<MedicationReminder>> fetchMedicationReminders(int familyId) async {
    final rows = await _client
        .from('medication_reminders')
        .select()
        .eq('family_id', familyId)
        .order('schedule_time', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(MedicationReminder.fromJson)
        .toList();
  }

  Future<MedicationReminder> createMedicationReminder(
    MedicationReminder reminder,
  ) async {
    final inserted = await _client
        .from('medication_reminders')
        .insert(reminder.toJson())
        .select()
        .single();

    return MedicationReminder.fromJson(inserted);
  }

  Future<MedicationReminder> toggleMedicationTaken(
    MedicationReminder reminder,
    String todayIso,
  ) async {
    if (reminder.id == null) return reminder;
    final newTakenState = !reminder.takenToday;
    final updated = await _client
        .from('medication_reminders')
        .update({
          'taken_today': newTakenState,
          'last_taken_at': newTakenState ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', reminder.id!)
        .select()
        .single();

    return MedicationReminder.fromJson(updated);
  }

  Future<void> deleteMedicationReminder(int id) async {
    await _client.from('medication_reminders').delete().eq('id', id);
  }

  // ===========================================================================
  // WATER TRACKERS
  // ===========================================================================

  Future<List<WaterTracker>> fetchWaterTrackers(int familyId) async {
    final rows = await _client
        .from('water_trackers')
        .select()
        .eq('family_id', familyId)
        .order('id', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(WaterTracker.fromJson)
        .toList();
  }

  Future<WaterTracker> updateWaterIntake({
    required WaterTracker tracker,
    required int newIntakeMl,
  }) async {
    final clamped = newIntakeMl.clamp(0, 10000);
    if (tracker.id == null) {
      final inserted = await _client
          .from('water_trackers')
          .insert(tracker.copyWith(currentMl: clamped).toJson())
          .select()
          .single();
      return WaterTracker.fromJson(inserted);
    }

    final updated = await _client
        .from('water_trackers')
        .update({
          'current_ml': clamped,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tracker.id!)
        .select()
        .single();

    return WaterTracker.fromJson(updated);
  }

  // ===========================================================================
  // PARTNER & FRIEND INVITATIONS
  // ===========================================================================

  Future<List<PartnerInvitation>> fetchPartnerInvitations(int familyId) async {
    final rows = await _client
        .from('partner_invitations')
        .select()
        .eq('family_id', familyId)
        .order('id', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PartnerInvitation.fromJson)
        .toList();
  }

  Future<PartnerInvitation> createPartnerInvitation(
    PartnerInvitation invitation,
  ) async {
    final inserted = await _client
        .from('partner_invitations')
        .insert(invitation.toJson())
        .select()
        .single();

    return PartnerInvitation.fromJson(inserted);
  }

  RealtimeChannel subscribeToFamilyChanges({
    required int familyId,
    required VoidCallback onDataChanged,
  }) {
    final channel = _client.channel('family_sync_$familyId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule_blocks',
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'focus_sessions',
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'medication_reminders',
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'water_trackers',
          callback: (_) => onDataChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'partner_invitations',
          callback: (_) => onDataChanged(),
        )
        .subscribe();
    return channel;
  }
}
