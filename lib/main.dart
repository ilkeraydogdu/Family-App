import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'data/repositories/planner_repository.dart';
import 'data/services/device_notification_service.dart';
import 'data/services/prayer_time_service.dart';
import 'data/services/supabase_family_service.dart';
import 'data/services/voice_reminder_service.dart';
import 'ui/view_models/planner_view_model.dart';
import 'ui/views/home_shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final supabaseService = SupabaseFamilyService();
  final prayerService = PrayerTimeService();
  final voiceService = VoiceReminderService();
  final notificationService = DeviceNotificationService();
  final repository = PlannerRepository(
    supabaseService: supabaseService,
    prayerService: prayerService,
  );
  final viewModel = PlannerViewModel(
    repository: repository,
    voiceService: voiceService,
    notificationService: notificationService,
  )..initialize();

  runApp(FamilyPlannerApp(viewModel: viewModel));
}

class FamilyPlannerApp extends StatelessWidget {
  final PlannerViewModel viewModel;

  const FamilyPlannerApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aile Düzeni & Ajanda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          primary: const Color(0xFF1E293B),
          secondary: const Color(0xFF0F766E),
          surface: Colors.white,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: HomeShellView(viewModel: viewModel),
    );
  }
}
