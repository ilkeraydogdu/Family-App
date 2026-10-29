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
        .subscribe();
    return channel;
  }
}
