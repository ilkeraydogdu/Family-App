import 'package:flutter_test/flutter_test.dart';
import 'package:family_app/data/services/prayer_time_service.dart';
import 'package:family_app/domain/models/family_models.dart';

void main() {
  test('PrayerTimeService calculates offsets and durations accurately', () {
    expect(PrayerTimeService.addMinutesToTime('06:00', 45), '06:45');
    expect(PrayerTimeService.addMinutesToTime('06:00', -30), '05:30');
    expect(PrayerTimeService.durationMinutes('09:00', '11:00'), 120);
  });

  test('ScheduleBlock serializes and deserializes checklist items', () {
    final json = {
      'id': 10,
      'family_id': 1,
      'owner_role': 'wife',
      'title': 'Gitar Dersi',
      'description': 'Sabah 09:00 - 11:00 gitar dersi',
      'category': 'lesson',
      'plan_date': '2026-10-30',
      'is_recurring_daily': true,
      'recurrence_days': [1, 2, 3, 4, 5],
      'start_time': '09:00',
      'end_time': '11:00',
      'is_prayer_anchored': false,
      'remind_before_minutes': 15,
      'repeat_count': 3,
      'repeat_interval_minutes': 5,
      'phone_lock_enabled': true,
      'allow_calls_only': true,
      'status': 'planned',
      'checklist_items': [
        {'id': '1', 'title': 'Akor çalışması', 'done': true},
        {'id': '2', 'title': 'Ritim tekrarı', 'done': false},
      ],
    };

    final block = ScheduleBlock.fromJson(json);
    expect(block.title, 'Gitar Dersi');
    expect(block.ownerLabel, 'Kişisel (Eşim)');
    expect(block.completedChecklistCount, 1);
    expect(block.checklistItems.length, 2);
  });

  test('MedicationReminder and WaterTracker serialize and compute progress', () {
    final med = MedicationReminder.fromJson({
      'id': 1,
      'family_id': 1,
      'owner_role': 'husband',
      'medication_name': 'Omega-3 & D3 Vitamini',
      'dosage': '1 Kapsül',
      'reminder_time': '08:30',
      'meal_relation': 'Tok Karnına',
      'taken_today': true,
    });
    expect(med.medicationName, 'Omega-3 & D3 Vitamini');
    expect(med.takenToday, isTrue);

    final water = WaterTracker.fromJson({
      'id': 1,
      'family_id': 1,
      'owner_role': 'husband',
      'daily_goal_ml': 2500,
      'current_intake_ml': 1250,
      'cup_size_ml': 250,
      'reminder_interval_minutes': 90,
      'reminder_enabled': true,
    });
    expect(water.progressRatio, 0.5);
    expect(water.completedCups, 5);
    expect(water.totalGoalCups, 10);
  });
}
