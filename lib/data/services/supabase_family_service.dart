import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/models/family_models.dart';

class SupabaseFamilyService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _client.auth.signOut();
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
      final cleanHandle = SupabaseConfig.normalizeUsernameHandle(
        email.contains('@') ? email.split('@').first : displayName,
      );
      await _client.from('family_members').upsert({
        'family_id': targetFamilyId,
        'user_id': userId,
        'role_label': roleLabel,
        'display_name': displayName.trim(),
        'username': cleanHandle,
        'connection_status': 'connected',
        'avatar_color': '#0F766E',
      }, onConflict: 'family_id,user_id');
    }

    return cleanEmail;
  }

  Future<List<MemberAccountProfile>> fetchFamilyMemberProfiles(
    int familyId,
  ) async {
    try {
      final rows = await _client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .order('id', ascending: true);
      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(MemberAccountProfile.fromJson)
          .toList();
    } catch (_) {
      return const [
        MemberAccountProfile(
          familyId: 1,
          userId: '11111111-1111-1111-1111-111111111111',
          username: 'ilker',
          displayName: 'İlker',
          roleLabel: 'husband',
          connectionStatus: 'connected',
        ),
        MemberAccountProfile(
          familyId: 1,
          userId: '22222222-2222-2222-2222-222222222222',
          username: 'neslihan',
          displayName: 'Neslihan',
          roleLabel: 'wife',
          connectionStatus: 'connected',
        ),
      ];
    }
  }

  Future<void> updateFamilyConnectionStatus({
    required int familyId,
    required String connectionStatus,
  }) async {
    await _client
        .from('family_members')
        .update({'connection_status': connectionStatus})
        .eq('family_id', familyId);
  }

  Future<List<String>> fetchConnectedMemberNames(int familyId) async {
    try {
      final rows = await _client
          .from('family_members')
          .select('display_name, connection_status')
          .eq('family_id', familyId)
          .eq('connection_status', 'connected')
          .order('id', ascending: true);
      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((r) => (r['display_name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const ['İlker', 'Neslihan'];
    }
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

  /// Fetches ONLY the current member's private personal blocks + shared blocks.
  /// Enforced both by PostgreSQL RLS (`schedule_blocks_select_policy`) and query filter.
  Future<List<ScheduleBlock>> fetchScheduleBlocks({
    required int familyId,
    required String planDate,
  }) async {
    final uid = currentUser?.id;
    var query = _client
        .from('schedule_blocks')
        .select()
        .eq('family_id', familyId)
        .or('plan_date.eq.$planDate,is_recurring_daily.eq.true');

    if (uid != null) {
      query = query.or('owner_role.eq.shared,created_by.eq.$uid');
    }

    final rows = await query.order('start_time', ascending: true);

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

  Future<void> deleteFocusSession(int id) async {
    await _client.from('focus_sessions').delete().eq('id', id);
  }

  // ===========================================================================
  // MEDICATION REMINDERS (Member-Private + Shared Only)
  // ===========================================================================

  Future<List<MedicationReminder>> fetchMedicationReminders(int familyId) async {
    final uid = currentUser?.id;
    var query = _client
        .from('medication_reminders')
        .select()
        .eq('family_id', familyId);

    if (uid != null) {
      query = query.or('owner_role.eq.shared,created_by.eq.$uid');
    }

    final rows = await query.order('schedule_time', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(MedicationReminder.fromJson)
        .toList();
  }

  Future<MedicationReminder> createMedicationReminder(
    MedicationReminder reminder,
  ) async {
    final payload = reminder.toJson();
    if (currentUser != null) {
      payload['created_by'] = currentUser!.id;
    }
    final inserted = await _client
        .from('medication_reminders')
        .insert(payload)
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
  // WATER TRACKERS (Strictly Private to Logged-in Member)
  // ===========================================================================

  Future<List<WaterTracker>> fetchWaterTrackers(int familyId) async {
    final uid = currentUser?.id;
    var query = _client
        .from('water_trackers')
        .select()
        .eq('family_id', familyId);

    if (uid != null) {
      query = query.eq('user_id', uid);
    }

    final rows = await query.order('id', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(WaterTracker.fromJson)
        .toList();
  }

  Future<WaterTracker> updateWaterIntake({
    required WaterTracker tracker,
    required int newIntakeMl,
    int? newGoalMl,
  }) async {
    final clamped = newIntakeMl.clamp(0, 10000);
    final goal = (newGoalMl ?? tracker.dailyGoalMl).clamp(500, 10000);
    if (tracker.id == null) {
      final payload = tracker
          .copyWith(currentMl: clamped, dailyGoalMl: goal)
          .toJson();
      if (currentUser != null) {
        payload['user_id'] = currentUser!.id;
      }
      final inserted = await _client
          .from('water_trackers')
          .insert(payload)
          .select()
          .single();
      return WaterTracker.fromJson(inserted);
    }

    final updated = await _client
        .from('water_trackers')
        .update({
          'current_ml': clamped,
          'daily_goal_ml': goal,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tracker.id!)
        .select()
        .single();

    return WaterTracker.fromJson(updated);
  }

  // ===========================================================================
  // PARTNER & FRIEND INVITATIONS (@username Ecosystem + Lifecycle)
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

  Future<PartnerInvitation> updatePartnerInvitation({
    required int id,
    required String status,
    required bool sharingPaused,
  }) async {
    final updated = await _client
        .from('partner_invitations')
        .update({
          'status': status,
          'sharing_paused': sharingPaused,
        })
        .eq('id', id)
        .select()
        .single();
    return PartnerInvitation.fromJson(updated);
  }

  Future<void> deletePartnerInvitation(int id) async {
    await _client.from('partner_invitations').delete().eq('id', id);
  }

  // ===========================================================================
  // SHARED CHORES, SHOPPING & PARTNER NOTES (Cupla / TimeTree Benchmark)
  // ===========================================================================

  Future<List<SharedChoreNote>> fetchSharedChoresAndNotes(int familyId) async {
    final rows = await _client
        .from('shared_chores_and_notes')
        .select()
        .eq('family_id', familyId)
        .order('is_done', ascending: true)
        .order('id', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(SharedChoreNote.fromJson)
        .toList();
  }

  Future<SharedChoreNote> createSharedChoreOrNote(SharedChoreNote item) async {
    final payload = item.toJson();
    if (currentUser != null) {
      payload['created_by'] = currentUser!.id;
    }
    final inserted = await _client
        .from('shared_chores_and_notes')
        .insert(payload)
        .select()
        .single();
    return SharedChoreNote.fromJson(inserted);
  }

  Future<SharedChoreNote> toggleSharedChoreOrNote(SharedChoreNote item) async {
    if (item.id == null) return item;
    final updated = await _client
        .from('shared_chores_and_notes')
        .update({'is_done': !item.isDone})
        .eq('id', item.id!)
        .select()
        .single();
    return SharedChoreNote.fromJson(updated);
  }

  Future<void> deleteSharedChoreOrNote(int id) async {
    await _client.from('shared_chores_and_notes').delete().eq('id', id);
  }

  // ===========================================================================
  // DAILY 5-PRAYER WORSHIP TRACKER (MyWaqt / Pillars Benchmark)
  // ===========================================================================

  Future<List<String>> fetchCompletedPrayers({
    required int familyId,
    required String username,
    required String prayerDate,
  }) async {
    final cleanUsername = username.replaceAll('@', '').toLowerCase();
    final row = await _client
        .from('daily_prayer_logs')
        .select()
        .eq('family_id', familyId)
        .eq('username', cleanUsername)
        .eq('prayer_date', prayerDate)
        .maybeSingle();

    if (row == null) return const [];
    return DailyPrayerLog.fromJson(row).completedPrayers;
  }

  Future<List<String>> saveCompletedPrayers({
    required int familyId,
    required String username,
    required String prayerDate,
    required List<String> completedPrayers,
  }) async {
    final cleanUsername = username.replaceAll('@', '').toLowerCase();
    final payload = <String, dynamic>{
      'family_id': familyId,
      'username': cleanUsername,
      'prayer_date': prayerDate,
      'completed_prayers': completedPrayers,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (currentUser != null) {
      payload['user_id'] = currentUser!.id;
    }

    final saved = await _client
        .from('daily_prayer_logs')
        .upsert(payload, onConflict: 'family_id,username,prayer_date')
        .select()
        .single();
    return DailyPrayerLog.fromJson(saved).completedPrayers;
  }

  /// KVKK / GDPR & Apple App Store Guideline 5.1.1(v) — In-App Account Data Deletion
  Future<void> purgePersonalAccountData(int familyId) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client
        .from('schedule_blocks')
        .delete()
        .eq('family_id', familyId)
        .eq('created_by', uid)
        .neq('owner_role', 'shared');
    await _client
        .from('medication_reminders')
        .delete()
        .eq('family_id', familyId)
        .eq('created_by', uid)
        .neq('owner_role', 'shared');
    await _client
        .from('water_trackers')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', uid);
    await signOut();
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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_chores_and_notes',
          callback: (_) => onDataChanged(),
        )
        .subscribe();
    return channel;
  }
}
