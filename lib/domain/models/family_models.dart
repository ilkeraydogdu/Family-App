import 'dart:convert';

class ChecklistItem {
  final String id;
  final String title;
  final bool done;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.done,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    bool? done,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      done: json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'done': done,
    };
  }
}

class ScheduleBlock {
  final int? id;
  final int familyId;
  final String ownerRole; // 'husband' | 'wife' | 'shared'
  final String title;
  final String description;
  final String category; // 'sleep' | 'prayer' | 'commute' | 'work' | 'lesson' | 'personal' | 'shared' | 'focus' | 'general'
  final String planDate; // YYYY-MM-DD
  final bool isRecurringDaily;
  final List<int> recurrenceDays;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final bool isPrayerAnchored;
  final String? prayerName; // 'Fajr' | 'Dhuhr' | 'Asr' | 'Maghrib' | 'Isha'
  final int prayerOffsetMinutes;
  final bool voiceReminderEnabled;
  final int remindBeforeMinutes;
  final int repeatCount;
  final int repeatIntervalMinutes;
  final bool phoneLockEnabled;
  final bool allowCallsOnly;
  final String status; // 'planned' | 'checked_in' | 'completed' | 'skipped'
  final DateTime? checkedInAt;
  final DateTime? completedAt;
  final String skipReason;
  final String completionNotes;
  final List<ChecklistItem> checklistItems;

  const ScheduleBlock({
    this.id,
    required this.familyId,
    required this.ownerRole,
    required this.title,
    required this.description,
    required this.category,
    required this.planDate,
    required this.isRecurringDaily,
    required this.recurrenceDays,
    required this.startTime,
    required this.endTime,
    required this.isPrayerAnchored,
    this.prayerName,
    required this.prayerOffsetMinutes,
    required this.voiceReminderEnabled,
    required this.remindBeforeMinutes,
    required this.repeatCount,
    required this.repeatIntervalMinutes,
    required this.phoneLockEnabled,
    required this.allowCallsOnly,
    required this.status,
    this.checkedInAt,
    this.completedAt,
    required this.skipReason,
    required this.completionNotes,
    required this.checklistItems,
  });

  int get completedChecklistCount =>
      checklistItems.where((item) => item.done).length;

  String get ownerLabel {
    if (ownerRole == 'shared') {
      return 'Ortak Plan';
    }
    return 'Kişisel Plan (Özel)';
  }

  bool get isSharedPlan => ownerRole == 'shared';

  String get statusLabel {
    switch (status) {
      case 'checked_in':
        return 'Başladı / Aktif';
      case 'completed':
        return 'Tamamlandı';
      case 'skipped':
        return 'Atlandı';
      default:
        return 'Planlandı';
    }
  }

  ScheduleBlock copyWith({
    int? id,
    int? familyId,
    String? ownerRole,
    String? title,
    String? description,
    String? category,
    String? planDate,
    bool? isRecurringDaily,
    List<int>? recurrenceDays,
    String? startTime,
    String? endTime,
    bool? isPrayerAnchored,
    String? prayerName,
    int? prayerOffsetMinutes,
    bool? voiceReminderEnabled,
    int? remindBeforeMinutes,
    int? repeatCount,
    int? repeatIntervalMinutes,
    bool? phoneLockEnabled,
    bool? allowCallsOnly,
    String? status,
    DateTime? checkedInAt,
    DateTime? completedAt,
    String? skipReason,
    String? completionNotes,
    List<ChecklistItem>? checklistItems,
  }) {
    return ScheduleBlock(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      ownerRole: ownerRole ?? this.ownerRole,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      planDate: planDate ?? this.planDate,
      isRecurringDaily: isRecurringDaily ?? this.isRecurringDaily,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPrayerAnchored: isPrayerAnchored ?? this.isPrayerAnchored,
      prayerName: prayerName ?? this.prayerName,
      prayerOffsetMinutes: prayerOffsetMinutes ?? this.prayerOffsetMinutes,
      voiceReminderEnabled: voiceReminderEnabled ?? this.voiceReminderEnabled,
      remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      phoneLockEnabled: phoneLockEnabled ?? this.phoneLockEnabled,
      allowCallsOnly: allowCallsOnly ?? this.allowCallsOnly,
      status: status ?? this.status,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      completedAt: completedAt ?? this.completedAt,
      skipReason: skipReason ?? this.skipReason,
      completionNotes: completionNotes ?? this.completionNotes,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist_items'];
    List<ChecklistItem> parsedChecklist = [];
    if (rawChecklist is List) {
      parsedChecklist = rawChecklist
          .whereType<Map<String, dynamic>>()
          .map(ChecklistItem.fromJson)
          .toList();
    } else if (rawChecklist is String && rawChecklist.isNotEmpty) {
      final decoded = jsonDecode(rawChecklist);
      if (decoded is List) {
        parsedChecklist = decoded
            .whereType<Map<String, dynamic>>()
            .map(ChecklistItem.fromJson)
            .toList();
      }
    }

    final rawDays = json['recurrence_days'];
    List<int> parsedDays = const [1, 2, 3, 4, 5, 6, 7];
    if (rawDays is List) {
      parsedDays = rawDays.map((e) => (e as num).toInt()).toList();
    }

    return ScheduleBlock(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      ownerRole: (json['owner_role'] ?? 'shared').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      planDate: (json['plan_date'] ??
              DateTime.now().toIso8601String().substring(0, 10))
          .toString(),
      isRecurringDaily: json['is_recurring_daily'] == true,
      recurrenceDays: parsedDays,
      startTime: (json['start_time'] ?? '08:00').toString(),
      endTime: (json['end_time'] ?? '09:00').toString(),
      isPrayerAnchored: json['is_prayer_anchored'] == true,
      prayerName: json['prayer_name']?.toString(),
      prayerOffsetMinutes:
          (json['prayer_offset_minutes'] as num?)?.toInt() ?? 0,
      voiceReminderEnabled: json['voice_reminder_enabled'] != false,
      remindBeforeMinutes:
          (json['remind_before_minutes'] as num?)?.toInt() ?? 15,
      repeatCount: (json['repeat_count'] as num?)?.toInt() ?? 3,
      repeatIntervalMinutes:
          (json['repeat_interval_minutes'] as num?)?.toInt() ?? 5,
      phoneLockEnabled: json['phone_lock_enabled'] == true,
      allowCallsOnly: json['allow_calls_only'] != false,
      status: (json['status'] ?? 'planned').toString(),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      skipReason: (json['skip_reason'] ?? '').toString(),
      completionNotes: (json['completion_notes'] ?? '').toString(),
      checklistItems: parsedChecklist,
    );
  }

  Map<String, dynamic> toInsertOrUpdateJson() {
    return {
      'family_id': familyId,
      'owner_role': ownerRole,
      'title': title,
      'description': description,
      'category': category,
      'plan_date': planDate,
      'is_recurring_daily': isRecurringDaily,
      'recurrence_days': recurrenceDays,
      'start_time': startTime,
      'end_time': endTime,
      'is_prayer_anchored': isPrayerAnchored,
      'prayer_name': prayerName,
      'prayer_offset_minutes': prayerOffsetMinutes,
      'voice_reminder_enabled': voiceReminderEnabled,
      'remind_before_minutes': remindBeforeMinutes,
      'repeat_count': repeatCount,
      'repeat_interval_minutes': repeatIntervalMinutes,
      'phone_lock_enabled': phoneLockEnabled,
      'allow_calls_only': allowCallsOnly,
      'status': status,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'skip_reason': skipReason,
      'completion_notes': completionNotes,
      'checklist_items': checklistItems.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class MedicationReminder {
  final int? id;
  final int familyId;
  final String ownerRole; // 'husband' | 'wife' | 'shared'
  final String medicationName;
  final String dosage;
  final String scheduleTime;
  final String mealRelation; // 'before_meal' | 'after_meal' | 'with_water' or Turkish label
  final bool takenToday;
  final DateTime? lastTakenAt;
  final bool notifyDevice;

  const MedicationReminder({
    this.id,
    required this.familyId,
    required this.ownerRole,
    required this.medicationName,
    required this.dosage,
    String? scheduleTime,
    String? reminderTime,
    required this.mealRelation,
    required this.takenToday,
    this.lastTakenAt,
    this.notifyDevice = true,
  }) : scheduleTime = scheduleTime ?? reminderTime ?? '08:30';

  String get reminderTime => scheduleTime;

  String get mealRelationLabel {
    switch (mealRelation) {
      case 'before_meal':
      case 'Aç Karnına':
        return 'Aç Karnına';
      case 'with_water':
      case 'Bol Su İle':
        return 'Bol Su İle';
      default:
        return 'Tok Karnına';
    }
  }

  String get ownerLabel {
    if (ownerRole == 'shared') {
      return 'Ortak';
    }
    return 'Kişisel (Özel)';
  }

  MedicationReminder copyWith({
    int? id,
    int? familyId,
    String? ownerRole,
    String? medicationName,
    String? dosage,
    String? scheduleTime,
    String? mealRelation,
    bool? takenToday,
    DateTime? lastTakenAt,
    bool? notifyDevice,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      ownerRole: ownerRole ?? this.ownerRole,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      mealRelation: mealRelation ?? this.mealRelation,
      takenToday: takenToday ?? this.takenToday,
      lastTakenAt: lastTakenAt ?? this.lastTakenAt,
      notifyDevice: notifyDevice ?? this.notifyDevice,
    );
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    final rawMeal = (json['meal_relation'] ?? 'after_meal').toString();
    final mealLabel = switch (rawMeal) {
      'before_meal' => 'Aç Karnına',
      'with_water' => 'Bol Su İle',
      'after_meal' => 'Tok Karnına',
      _ => rawMeal,
    };
    return MedicationReminder(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      ownerRole: (json['owner_role'] ?? 'husband').toString(),
      medicationName: (json['medication_name'] ?? '').toString(),
      dosage: (json['dosage'] ?? '1 Tablet').toString(),
      scheduleTime:
          (json['schedule_time'] ?? json['reminder_time'] ?? '08:30')
              .toString(),
      mealRelation: mealLabel,
      takenToday: json['taken_today'] == true,
      lastTakenAt: json['last_taken_at'] != null
          ? DateTime.tryParse(json['last_taken_at'].toString())
          : null,
      notifyDevice: json['notify_device'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    final dbMeal = switch (mealRelation) {
      'Aç Karnına' || 'before_meal' => 'before_meal',
      'Bol Su İle' || 'with_water' => 'with_water',
      _ => 'after_meal',
    };
    return {
      'family_id': familyId,
      'owner_role': ownerRole,
      'medication_name': medicationName,
      'dosage': dosage,
      'schedule_time': scheduleTime,
      'meal_relation': dbMeal,
      'taken_today': takenToday,
      'last_taken_at': lastTakenAt?.toIso8601String(),
      'notify_device': notifyDevice,
    };
  }
}

class WaterTracker {
  final int? id;
  final int familyId;
  final String ownerRole; // 'husband' | 'wife'
  final String trackDate;
  final int dailyGoalMl;
  final int currentMl;
  final int cupSizeMl;
  final int reminderIntervalMinutes;
  final bool notifyDevice;

  const WaterTracker({
    this.id,
    required this.familyId,
    required this.ownerRole,
    String? trackDate,
    required this.dailyGoalMl,
    int? currentMl,
    int? currentIntakeMl,
    required this.cupSizeMl,
    required this.reminderIntervalMinutes,
    bool? notifyDevice,
    bool? reminderEnabled,
  }) : trackDate = trackDate ?? '2026-10-30',
       currentMl = currentMl ?? currentIntakeMl ?? 0,
       notifyDevice = notifyDevice ?? reminderEnabled ?? true;

  int get currentIntakeMl => currentMl;
  bool get reminderEnabled => notifyDevice;

  double get progress =>
      dailyGoalMl > 0 ? (currentMl / dailyGoalMl).clamp(0.0, 1.0) : 0.0;
  double get progressRatio => progress;

  int get cupsDrunk => cupSizeMl > 0 ? (currentMl / cupSizeMl).floor() : 0;
  int get completedCups => cupsDrunk;

  int get totalCups => cupSizeMl > 0 ? (dailyGoalMl / cupSizeMl).ceil() : 10;
  int get totalGoalCups => totalCups;

  WaterTracker copyWith({
    int? id,
    int? familyId,
    String? ownerRole,
    String? trackDate,
    int? dailyGoalMl,
    int? currentMl,
    int? currentIntakeMl,
    int? cupSizeMl,
    int? reminderIntervalMinutes,
    bool? notifyDevice,
  }) {
    return WaterTracker(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      ownerRole: ownerRole ?? this.ownerRole,
      trackDate: trackDate ?? this.trackDate,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      currentMl: currentMl ?? currentIntakeMl ?? this.currentMl,
      cupSizeMl: cupSizeMl ?? this.cupSizeMl,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      notifyDevice: notifyDevice ?? this.notifyDevice,
    );
  }

  factory WaterTracker.fromJson(Map<String, dynamic> json) {
    return WaterTracker(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      ownerRole: (json['owner_role'] ?? 'husband').toString(),
      trackDate: (json['track_date'] ??
              DateTime.now().toIso8601String().substring(0, 10))
          .toString(),
      dailyGoalMl: (json['daily_goal_ml'] as num?)?.toInt() ?? 2500,
      currentMl:
          (json['current_ml'] ?? json['current_intake_ml'] as num?)?.toInt() ??
              0,
      cupSizeMl: (json['cup_size_ml'] as num?)?.toInt() ?? 250,
      reminderIntervalMinutes:
          (json['reminder_interval_minutes'] as num?)?.toInt() ?? 90,
      notifyDevice: json['notify_device'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_id': familyId,
      'owner_role': ownerRole,
      'track_date': trackDate,
      'daily_goal_ml': dailyGoalMl,
      'current_ml': currentMl,
      'cup_size_ml': cupSizeMl,
      'reminder_interval_minutes': reminderIntervalMinutes,
      'notify_device': notifyDevice,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class MemberAccountProfile {
  final int? id;
  final int familyId;
  final String userId;
  final String username;
  final String displayName;
  final String roleLabel;
  final String connectionStatus; // 'connected' | 'paused' | 'removed'

  const MemberAccountProfile({
    this.id,
    required this.familyId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.roleLabel,
    this.connectionStatus = 'connected',
  });

  String get formattedHandle =>
      username.startsWith('@') ? username : '@$username';

  bool get isConnected => connectionStatus == 'connected';
  bool get isPaused => connectionStatus == 'paused';
  bool get isRemoved => connectionStatus == 'removed';

  factory MemberAccountProfile.fromJson(Map<String, dynamic> json) {
    final rawName = (json['display_name'] ?? 'Üye').toString();
    final rawUsername = (json['username'] ??
            rawName.toLowerCase().replaceAll(' ', '_'))
        .toString()
        .replaceAll('@', '');
    return MemberAccountProfile(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      userId: (json['user_id'] ?? '').toString(),
      username: rawUsername,
      displayName: rawName,
      roleLabel: (json['role_label'] ?? 'husband').toString(),
      connectionStatus: (json['connection_status'] ?? 'connected').toString(),
    );
  }
}

class PartnerInvitation {
  final int? id;
  final int familyId;
  final String inviterName;
  final String inviterUsername;
  final String inviteeLabel;
  final String targetUsername;
  final String relationType; // 'spouse' | 'friend' | 'family'
  final String inviteCode;
  final String status; // 'pending' | 'accepted' | 'paused'
  final bool sharingPaused;

  PartnerInvitation({
    this.id,
    required this.familyId,
    String? inviterName,
    String? inviterRole,
    String? inviterUsername,
    required this.inviteeLabel,
    String? targetUsername,
    String? inviteeEmail,
    String? relationType,
    String? relationshipType,
    required this.inviteCode,
    required this.status,
    this.sharingPaused = false,
    bool? allowSharedPlans,
  }) : inviterName = inviterName ?? (inviterRole == 'wife' ? 'Neslihan' : 'İlker'),
       inviterUsername = (inviterUsername ?? 'ilker').replaceAll('@', ''),
       targetUsername = (targetUsername ?? inviteeEmail ?? 'neslihan')
           .replaceAll('@', '')
           .split('@')
           .first,
       relationType = relationType ?? relationshipType ?? 'spouse';

  String get formattedInviterHandle => '@$inviterUsername';
  String get formattedTargetHandle => '@$targetUsername';

  String partnerDisplayFor(String currentUsername) {
    final cleanMe = currentUsername.replaceAll('@', '').toLowerCase();
    if (targetUsername.toLowerCase() == cleanMe &&
        inviterUsername.toLowerCase() != cleanMe) {
      return '$inviterName ($formattedInviterHandle)';
    }
    return '$inviteeLabel ($formattedTargetHandle)';
  }

  String get relationshipType => relationLabel;

  String get relationLabel {
    switch (relationType) {
      case 'friend':
      case 'Arkadaş / Çalışma Partneri':
        return 'Arkadaş / Çalışma Partneri';
      case 'family':
      case 'Aile Üyesi':
        return 'Aile Üyesi';
      default:
        return 'Eş (Ortak Ajanda)';
    }
  }

  PartnerInvitation copyWith({
    int? id,
    int? familyId,
    String? inviterName,
    String? inviterUsername,
    String? inviteeLabel,
    String? targetUsername,
    String? relationType,
    String? inviteCode,
    String? status,
    bool? sharingPaused,
  }) {
    return PartnerInvitation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      inviterName: inviterName ?? this.inviterName,
      inviterUsername: inviterUsername ?? this.inviterUsername,
      inviteeLabel: inviteeLabel ?? this.inviteeLabel,
      targetUsername: targetUsername ?? this.targetUsername,
      relationType: relationType ?? this.relationType,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      sharingPaused: sharingPaused ?? this.sharingPaused,
    );
  }

  factory PartnerInvitation.fromJson(Map<String, dynamic> json) {
    return PartnerInvitation(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      inviterName: (json['inviter_name'] ?? 'İlker').toString(),
      inviterUsername: (json['inviter_username'] ?? 'ilker').toString(),
      inviteeLabel: (json['invitee_label'] ?? 'Neslihan').toString(),
      targetUsername: (json['target_username'] ?? 'neslihan').toString(),
      relationType: (json['relation_type'] ?? 'spouse').toString(),
      inviteCode: (json['invite_code'] ?? 'AYDOGDU26').toString(),
      status: (json['status'] ?? 'accepted').toString(),
      sharingPaused: json['sharing_paused'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final dbRelation = switch (relationType) {
      'Arkadaş / Çalışma Partneri' || 'friend' => 'friend',
      'Aile Üyesi' || 'family' => 'family',
      _ => 'spouse',
    };
    return {
      'family_id': familyId,
      'inviter_name': inviterName,
      'inviter_username': inviterUsername.replaceAll('@', ''),
      'invitee_label': inviteeLabel,
      'target_username': targetUsername.replaceAll('@', ''),
      'relation_type': dbRelation,
      'invite_code': inviteCode,
      'status': status,
      'sharing_paused': sharingPaused,
    };
  }
}

class PrayerTimesDay {
  final String city;
  final String country;
  final String dateReadable;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const PrayerTimesDay({
    required this.city,
    required this.country,
    required this.dateReadable,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  String? timeForPrayer(String? prayerKey) {
    switch (prayerKey) {
      case 'Fajr':
        return fajr;
      case 'Sunrise':
        return sunrise;
      case 'Dhuhr':
        return dhuhr;
      case 'Asr':
        return asr;
      case 'Maghrib':
        return maghrib;
      case 'Isha':
        return isha;
      default:
        return null;
    }
  }

  static String turkishPrayerName(String? key) {
    switch (key) {
      case 'Fajr':
        return 'İmsak / Sabah';
      case 'Sunrise':
        return 'Güneş';
      case 'Dhuhr':
        return 'Öğle';
      case 'Asr':
        return 'İkindi';
      case 'Maghrib':
        return 'Akşam';
      case 'Isha':
        return 'Yatsı';
      default:
        return 'Namaz Vakti';
    }
  }

  factory PrayerTimesDay.fallback({String city = 'Istanbul'}) {
    return PrayerTimesDay(
      city: city,
      country: 'Turkey',
      dateReadable: DateTime.now().toIso8601String().substring(0, 10),
      fajr: '05:52',
      sunrise: '07:18',
      dhuhr: '13:06',
      asr: '16:08',
      maghrib: '18:39',
      isha: '19:59',
    );
  }
}

class FocusSession {
  final int? id;
  final int familyId;
  final String targetRole;
  final String title;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool allowCallsOnly;
  final String emergencyContactPhone;

  const FocusSession({
    this.id,
    required this.familyId,
    required this.targetRole,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.allowCallsOnly,
    required this.emergencyContactPhone,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      targetRole: (json['target_role'] ?? 'shared').toString(),
      title: (json['title'] ?? '').toString(),
      startTime: (json['start_time'] ?? '20:30').toString(),
      endTime: (json['end_time'] ?? '22:00').toString(),
      isActive: json['is_active'] != false,
      allowCallsOnly: json['allow_calls_only'] != false,
      emergencyContactPhone:
          (json['emergency_contact_phone'] ?? '+90 555 000 00 00').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_id': familyId,
      'target_role': targetRole,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
      'allow_calls_only': allowCallsOnly,
      'emergency_contact_phone': emergencyContactPhone,
    };
  }
}

class FamilyProfile {
  final int id;
  final String name;
  final String inviteCode;
  final String city;
  final String country;
  final String wakeUpTime;
  final String sleepTime;

  const FamilyProfile({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.city,
    required this.country,
    required this.wakeUpTime,
    required this.sleepTime,
  });

  factory FamilyProfile.fromJson(Map<String, dynamic> json) {
    return FamilyProfile(
      id: (json['id'] as num?)?.toInt() ?? 1,
      name: (json['name'] ?? 'Aydoğdu Ailesi').toString(),
      inviteCode: (json['invite_code'] ?? 'AYDOGDU26').toString(),
      city: (json['city'] ?? 'Istanbul').toString(),
      country: (json['country'] ?? 'Turkey').toString(),
      wakeUpTime: (json['wake_up_time'] ?? '05:00').toString(),
      sleepTime: (json['sleep_time'] ?? '23:00').toString(),
    );
  }
}

class DailySpiritualContent {
  final String dateKey;
  final String hadithText;
  final String hadithSource;
  final String hadithNumber;
  final String duaArabic;
  final String duaTurkish;
  final String duaSource;
  final String morningEveningZikir;
  final bool isLiveFromOpenSource;

  const DailySpiritualContent({
    required this.dateKey,
    required this.hadithText,
    required this.hadithSource,
    required this.hadithNumber,
    required this.duaArabic,
    required this.duaTurkish,
    required this.duaSource,
    required this.morningEveningZikir,
    this.isLiveFromOpenSource = true,
  });

  DailySpiritualContent copyWith({
    String? dateKey,
    String? hadithText,
    String? hadithSource,
    String? hadithNumber,
    String? duaArabic,
    String? duaTurkish,
    String? duaSource,
    String? morningEveningZikir,
    bool? isLiveFromOpenSource,
  }) {
    return DailySpiritualContent(
      dateKey: dateKey ?? this.dateKey,
      hadithText: hadithText ?? this.hadithText,
      hadithSource: hadithSource ?? this.hadithSource,
      hadithNumber: hadithNumber ?? this.hadithNumber,
      duaArabic: duaArabic ?? this.duaArabic,
      duaTurkish: duaTurkish ?? this.duaTurkish,
      duaSource: duaSource ?? this.duaSource,
      morningEveningZikir: morningEveningZikir ?? this.morningEveningZikir,
      isLiveFromOpenSource: isLiveFromOpenSource ?? this.isLiveFromOpenSource,
    );
  }
}

class ActiveAlarmSession {
  final ScheduleBlock block;
  final int currentAttempt;
  final int maxAttempts;
  final String selectedToneId; // 'harmonic_chime' | 'classic_alarm' | 'gentle_piano' | 'urgent_pulse'
  final bool voiceTitleAfterChime;
  final DateTime triggeredAt;
  final DateTime? snoozedUntil;

  const ActiveAlarmSession({
    required this.block,
    required this.currentAttempt,
    required this.maxAttempts,
    this.selectedToneId = 'harmonic_chime',
    this.voiceTitleAfterChime = false,
    required this.triggeredAt,
    this.snoozedUntil,
  });

  ActiveAlarmSession copyWith({
    ScheduleBlock? block,
    int? currentAttempt,
    int? maxAttempts,
    String? selectedToneId,
    bool? voiceTitleAfterChime,
    DateTime? triggeredAt,
    DateTime? snoozedUntil,
  }) {
    return ActiveAlarmSession(
      block: block ?? this.block,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      selectedToneId: selectedToneId ?? this.selectedToneId,
      voiceTitleAfterChime: voiceTitleAfterChime ?? this.voiceTitleAfterChime,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      snoozedUntil: snoozedUntil,
    );
  }
}

class SharedChoreNote {
  final int? id;
  final int familyId;
  final String authorUsername;
  final String assignedTo; // '@ilker' | '@neslihan' | 'Ortak'
  final String category; // 'shopping' | 'chore' | 'note' | 'date_idea'
  final String title;
  final bool isDone;

  const SharedChoreNote({
    this.id,
    required this.familyId,
    required this.authorUsername,
    this.assignedTo = 'Ortak',
    this.category = 'shopping',
    required this.title,
    this.isDone = false,
  });

  String get formattedAuthorHandle =>
      authorUsername.startsWith('@') ? authorUsername : '@$authorUsername';

  String get categoryLabel {
    switch (category) {
      case 'shopping':
        return 'Market & Alışveriş';
      case 'chore':
        return 'Ev & Sorumluluk';
      case 'date_idea':
        return 'Birlikte Etkinlik';
      default:
        return 'Eşe Not';
    }
  }

  SharedChoreNote copyWith({
    int? id,
    int? familyId,
    String? authorUsername,
    String? assignedTo,
    String? category,
    String? title,
    bool? isDone,
  }) {
    return SharedChoreNote(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      authorUsername: authorUsername ?? this.authorUsername,
      assignedTo: assignedTo ?? this.assignedTo,
      category: category ?? this.category,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  factory SharedChoreNote.fromJson(Map<String, dynamic> json) {
    return SharedChoreNote(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      authorUsername: (json['author_username'] ?? 'ilker')
          .toString()
          .replaceAll('@', ''),
      assignedTo: (json['assigned_to'] ?? 'Ortak').toString(),
      category: (json['category'] ?? 'shopping').toString(),
      title: (json['title'] ?? '').toString(),
      isDone: json['is_done'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_id': familyId,
      'author_username': authorUsername.replaceAll('@', ''),
      'assigned_to': assignedTo,
      'category': category,
      'title': title,
      'is_done': isDone,
    };
  }
}

class DailyPrayerLog {
  final int? id;
  final int familyId;
  final String username;
  final String prayerDate;
  final List<String> completedPrayers; // ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']

  const DailyPrayerLog({
    this.id,
    required this.familyId,
    required this.username,
    required this.prayerDate,
    this.completedPrayers = const [],
  });

  bool isCompleted(String key) => completedPrayers.contains(key);

  factory DailyPrayerLog.fromJson(Map<String, dynamic> json) {
    final rawList = json['completed_prayers'];
    final parsed = <String>[];
    if (rawList is List) {
      for (final item in rawList) {
        parsed.add(item.toString());
      }
    }
    return DailyPrayerLog(
      id: (json['id'] as num?)?.toInt(),
      familyId: (json['family_id'] as num?)?.toInt() ?? 1,
      username: (json['username'] ?? 'ilker').toString(),
      prayerDate: (json['prayer_date'] ??
              DateTime.now().toIso8601String().substring(0, 10))
          .toString(),
      completedPrayers: parsed,
    );
  }
}


