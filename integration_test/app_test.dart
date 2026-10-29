import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:family_app/core/config/supabase_config.dart';
import 'package:family_app/data/repositories/planner_repository.dart';
import 'package:family_app/data/services/prayer_time_service.dart';
import 'package:family_app/data/services/supabase_family_service.dart';
import 'package:family_app/data/services/voice_reminder_service.dart';
import 'package:family_app/ui/view_models/planner_view_model.dart';
import 'package:family_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full E2E Family Planner flow across all tabs and Supabase sync',
      (WidgetTester tester) async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
    } catch (_) {
      // Already initialized
    }

    final viewModel = PlannerViewModel(
      repository: PlannerRepository(
        supabaseService: SupabaseFamilyService(),
        prayerService: PrayerTimeService(),
      ),
      voiceService: VoiceReminderService(),
    );

    await tester.pumpWidget(FamilyPlannerApp(viewModel: viewModel));
    await viewModel.initialize();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 1. Verify Family header & Live Prayer Times card loaded
    expect(find.textContaining('Aydoğdu Ailesi'), findsOneWidget);
    expect(find.textContaining('Canlı Namaz Vakitleri'), findsOneWidget);

    // 2. Verify schedule blocks loaded from Supabase
    expect(find.textContaining('Güne Uyanış'), findsWidgets);

    // 3. Switch to Tab 2: Ben & Eşim (Couple Comparison)
    await tester.tap(find.text('Ben & Eşim'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Yan Yana Eş Görünümü'), findsOneWidget);
    expect(find.textContaining('İlker\'in Günü'), findsOneWidget);
    expect(find.textContaining('Eşimin Günü'), findsOneWidget);

    // 4. Switch to Tab 3: Odak & Kilit (Phone Lockdown Shield)
    await tester.tap(find.text('Odak & Kilit'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Telefon Kısıtlama & Sadece Aramalar Modu'),
      findsOneWidget,
    );

    // Activate Lockdown Shield
    await tester.tap(
      find.textContaining('Kısıtlama Kalkanını Şimdi Başlat'),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('TELEFON KULLANIM DIŞI • SADECE ARAMALAR AÇIK'),
      findsOneWidget,
    );

    // Simulate incoming call while phone is locked
    await tester.tap(
      find.textContaining('Gelen Arama Geldiğinde Nasıl Görünür?'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Gelen Arama: Eşim'), findsOneWidget);

    // Exit Lockdown Shield
    await tester.tap(
      find.textContaining('Acil Durum: Kısıtlama Modundan Çık'),
    );
    await tester.pumpAndSettle();

    // 5. Switch to Tab 4: Takip & Özet (Statistics & Skipped Lessons Tracker)
    await tester.tap(find.text('Takip & Özet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tamamlanan'), findsOneWidget);
    expect(
      find.textContaining('Atlanan Dersler & Planlar Takibi'),
      findsOneWidget,
    );

    // 6. Return to Tab 1: Günlük Ajanda and switch active spouse role
    await tester.tap(find.text('Günlük Ajanda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktif: İlker'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Aktif: Eşim'), findsOneWidget);
  });
}
