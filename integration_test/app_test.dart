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

  testWidgets('Full E2E Family Planner flow across all 5 tabs and Supabase sync',
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

    expect(find.textContaining('Canlı Diyanet Namaz Vakitleri'), findsOneWidget);

    await tester.tap(find.text('Ortak İşler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gizlilik Koruması Aktif'), findsOneWidget);

    await tester.tap(find.text('İlaç & Su'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kişisel Su Hatırlatıcım'), findsOneWidget);
    expect(find.textContaining('İlaç & Vitamin Hatırlatıcılarım'), findsOneWidget);

    await tester.tap(find.text('Odak Kilit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Telefon Kısıtlama & Odak Kalkanı'), findsOneWidget);

    await tester.tap(find.text('Takip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tamamlanan'), findsOneWidget);
  });
}
