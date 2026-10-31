import 'package:flutter/material.dart';

import '../../data/services/voice_reminder_service.dart';
import '../../domain/models/family_models.dart';
import '../core/app_svg_icons.dart';
import '../view_models/planner_view_model.dart';

class FullScreenAlarmOverlay extends StatefulWidget {
  final PlannerViewModel viewModel;
  final ActiveAlarmSession session;

  const FullScreenAlarmOverlay({
    super.key,
    required this.viewModel,
    required this.session,
  });

  @override
  State<FullScreenAlarmOverlay> createState() => _FullScreenAlarmOverlayState();
}

class _FullScreenAlarmOverlayState extends State<FullScreenAlarmOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final session = widget.session;
    final block = session.block;
    final snoozeMins = block.repeatIntervalMinutes.clamp(1, 30);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Alarm Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSvgIcon(
                      svgData: AppSvgs.bellNotification,
                      size: 14,
                      color: Color(0xFF34D399),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CANLI PLAN ALARMI • ${session.currentAttempt} / ${session.maxAttempts} TEKRAR',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Pulsing Alarm Ring Graphic + Big Plan Time
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.12);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: scale * 1.16,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.08 * (1.2 - _pulseController.value),
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.18,
                            ),
                            border: Border.all(
                              color: const Color(0xFF34D399),
                              width: 1.8,
                            ),
                          ),
                          child: const Center(
                            child: AppSvgIcon(
                              svgData: AppSvgs.bellNotification,
                              size: 26,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              Text(
                block.startTime,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${block.startTime} - ${block.endTime} • ${block.remindBeforeMinutes} dk önceden hatırlatma',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),

              // Plan Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            block.ownerRole == 'shared'
                                ? 'Ortak Planımız'
                                : 'Kişisel Planım (${vm.activeDisplayName})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (block.isPrayerAnchored)
                          const Text(
                            'Canlı Namaz Hizalı',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF34D399),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      block.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (block.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        block.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    if (block.checklistItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      const SizedBox(height: 8),
                      const Text(
                        'Başlamadan Önce Hazırlık Maddeleri:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...block.checklistItems.take(2).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  AppSvgIcon(
                                    svgData: item.done
                                        ? AppSvgs.checkCircle
                                        : AppSvgs.clock,
                                    size: 13,
                                    color: item.done
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Polyphonic Alarm Melody Selector Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        AppSvgIcon(
                          svgData: AppSvgs.voiceWave,
                          size: 15,
                          color: Color(0xFF38BDF8),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alarm Zil Sesi Seçimi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: VoiceReminderService.alarmToneLabels.entries
                          .map((entry) {
                        final isSelected = session.selectedToneId == entry.key;
                        return GestureDetector(
                          onTap: () => vm.changeAlarmTone(entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Primary Action 1: Check-in & Stop Alarm ("Geldim / Başladım — Alarmı Kapat")
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('alarm_checkin_stop_btn'),
                  onPressed: () => vm.checkInFromActiveAlarm(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF052E16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSvgIcon(
                        svgData: AppSvgs.checkCircle,
                        size: 18,
                        color: Color(0xFF052E16),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Derse Geldim / Başladım (Alarmı Kapat)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary Action 2 & 3: Snooze ("Ertele") & Dismiss ("Sustur")
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('alarm_snooze_btn'),
                      onPressed: () =>
                          vm.snoozeActiveAlarm(customMinutes: snoozeMins),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFBBF24),
                        side: const BorderSide(color: Color(0xFFD97706)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '$snoozeMins Dk Ertele (Tekrar Çal)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('alarm_dismiss_btn'),
                      onPressed: () => vm.dismissActiveAlarm(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCBD5E1),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Alarmı Sustur',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
