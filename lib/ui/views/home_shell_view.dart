import 'package:flutter/material.dart';

import '../../domain/models/family_models.dart';
import '../core/app_svg_icons.dart';
import '../view_models/planner_view_model.dart';
import '../widgets/auth_and_invite_sheet.dart';
import '../widgets/block_editor_sheet.dart';
import '../widgets/completion_review_sheet.dart';
import '../widgets/full_screen_alarm_overlay.dart';
import '../widgets/spiritual_widget_sheet.dart';
import 'auth_onboarding_view.dart';
import 'phone_lockdown_shield_view.dart';

class HomeShellView extends StatefulWidget {
  final PlannerViewModel viewModel;

  const HomeShellView({super.key, required this.viewModel});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        if (!vm.isLoading && !vm.isAuthenticated) {
          return AuthOnboardingView(viewModel: vm);
        }

        if (vm.isPhoneLockShieldActive) {
          return PhoneLockdownShieldView(
            reasonTitle: vm.activeLockdownReason,
            onExitLockdown: vm.deactivatePhoneLockdownShield,
          );
        }

        if (vm.activeAlarmSession != null) {
          return FullScreenAlarmOverlay(
            viewModel: vm,
            session: vm.activeAlarmSession!,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7F9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 16,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFE2E8F0)),
            ),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(
                    svgData: AppSvgs.calendar,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vm.activeDisplayName} (${vm.activeUsernameHandle})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${vm.familyProfile.wakeUpTime} - ${vm.familyProfile.sleepTime} • ${vm.familyProfile.city}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Member Account & Partner Invite Button (@username ecosystem, zero email!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _openAuthAndInviteModal(context, vm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppSvgIcon(
                          svgData: AppSvgs.userSingle,
                          size: 14,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          vm.activeUsernameHandle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Rutin & Şehir Ayarları',
                onPressed: () => _openFamilySettingsDialog(context, vm),
                icon: const AppSvgIcon(
                  svgData: AppSvgs.sliders,
                  size: 19,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (vm.lastSpokenReminder != null)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const AppSvgIcon(
                              svgData: AppSvgs.bellNotification,
                              color: Color(0xFF38BDF8),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vm.lastSpokenReminder!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: vm.stopAllVoiceReminders,
                              child: const Text(
                                'Sustur',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: switch (_selectedTabIndex) {
                        0 => _buildDailyAgendaTab(context, vm),
                        1 => _buildSharedPlansAndPartnersTab(context, vm),
                        2 => _buildHealthWaterAndMedicationsTab(context, vm),
                        3 => _buildFocusLockdownTab(context, vm),
                        _ => _buildAnalyticsAndSkippedTab(context, vm),
                      },
                    ),
                  ],
                ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFF1F5F9),
              height: 66,
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _selectedTabIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: AppSvgIcon(
                    svgData: AppSvgs.calendar,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  selectedIcon: AppSvgIcon(
                    svgData: AppSvgs.calendar,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  label: 'Ajandam',
                ),
                NavigationDestination(
                  icon: AppSvgIcon(
                    svgData: AppSvgs.usersCouple,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  selectedIcon: AppSvgIcon(
                    svgData: AppSvgs.usersCouple,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  label: 'Ortak İşler',
                ),
                NavigationDestination(
                  icon: AppSvgIcon(
                    svgData: AppSvgs.waterDrop,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  selectedIcon: AppSvgIcon(
                    svgData: AppSvgs.waterDrop,
                    color: Color(0xFF0F766E),
                    size: 20,
                  ),
                  label: 'İlaç & Su',
                ),
                NavigationDestination(
                  icon: AppSvgIcon(
                    svgData: AppSvgs.shieldLock,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  selectedIcon: AppSvgIcon(
                    svgData: AppSvgs.shieldLock,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  label: 'Odak Kilit',
                ),
                NavigationDestination(
                  icon: AppSvgIcon(
                    svgData: AppSvgs.noteSummary,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  selectedIcon: AppSvgIcon(
                    svgData: AppSvgs.noteSummary,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                  label: 'Takip',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 1: KİŞİSEL + ORTAK GÜNLÜK SAATLİK AJANDAM
  // ===========================================================================
  Widget _buildDailyAgendaTab(BuildContext context, PlannerViewModel vm) {
    final blocks = vm.filteredBlocks;

    return RefreshIndicator(
      onRefresh: vm.syncAllWithLivePrayerTimes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
        children: [
          if (vm.snoozedAlarmSummary != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const AppSvgIcon(
                    svgData: AppSvgs.bellNotification,
                    size: 16,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.snoozedAlarmSummary!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.stopAllVoiceReminders,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF92400E),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          DailySpiritualCard(
            viewModel: vm,
            onOpenWidgetCustomizer: () =>
                _openSpiritualWidgetSheet(context, vm),
          ),
          const SizedBox(height: 12),
          _buildLivePrayerTimesBanner(vm),
          const SizedBox(height: 12),
          _buildQuickHealthSummaryStrip(vm),
          const SizedBox(height: 12),
          _buildSevenDayCalendarStrip(vm),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saatlik Plan & Rutinlerim',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('add_schedule_block_btn'),
                onPressed: () => _openBlockEditor(context, vm, null),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const AppSvgIcon(
                  svgData: AppSvgs.plus,
                  color: Colors.white,
                  size: 14,
                ),
                label: const Text(
                  'Yeni Plan Ekle',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterRow(vm),
          const SizedBox(height: 12),
          if (blocks.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: _minimalCardDecoration(),
              child: const Center(
                child: Text(
                  'Seçili filtrede henüz saatlik plan bulunmuyor.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ...blocks.map(
              (block) => _buildScheduleBlockCard(context, vm, block),
            ),
        ],
      ),
    );
  }

  Widget _buildSevenDayCalendarStrip(PlannerViewModel vm) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      vm.selectedDate.year,
      vm.selectedDate.month,
      vm.selectedDate.day,
    );
    const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _minimalCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppSvgIcon(
                svgData: AppSvgs.calendar,
                color: Color(0xFF0F172A),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Haftalık Gün Seçimi (${vm.formattedSelectedDate})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (selectedDay != todayDate)
                InkWell(
                  onTap: () => vm.selectDate(todayDate),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Bugüne Dön',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (idx) {
              final d = todayDate.add(Duration(days: idx - 1));
              final isSelected =
                  d.year == selectedDay.year &&
                  d.month == selectedDay.month &&
                  d.day == selectedDay.day;
              final isToday =
                  d.year == todayDate.year &&
                  d.month == todayDate.month &&
                  d.day == todayDate.day;
              final label = dayLabels[d.weekday - 1];

              return Expanded(
                child: GestureDetector(
                  onTap: () => vm.selectDate(d),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : isToday
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : isToday
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isToday ? 'Bugün' : label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : isToday
                                ? const Color(0xFF0F766E)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _computeNextPrayerSummary(PrayerTimesDay p) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final items = [
      ('Sabah', p.fajr),
      ('Güneş', p.sunrise),
      ('Öğle', p.dhuhr),
      ('İkindi', p.asr),
      ('Akşam', p.maghrib),
      ('Yatsı', p.isha),
    ];
    for (final entry in items) {
      final parts = entry.$2.split(':');
      if (parts.length >= 2) {
        final mins =
            (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        if (mins > nowMins) {
          final diff = mins - nowMins;
          final hrs = diff ~/ 60;
          final remMins = diff % 60;
          final leftStr = hrs > 0 ? '${hrs}s ${remMins}dk' : '${remMins}dk';
          return '${entry.$1} ${entry.$2} ($leftStr)';
        }
      }
    }
    return 'Sabah ${p.fajr} (Yarın sabah)';
  }

  Widget _buildLivePrayerTimesBanner(PlannerViewModel vm) {
    final p = vm.prayerTimes;
    final nextPrayerLabel = _computeNextPrayerSummary(p);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const AppSvgIcon(
                  svgData: AppSvgs.prayerCrescent,
                  color: Color(0xFF0F766E),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canlı Namaz Vakitleri (${p.city})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$nextPrayerLabel • ${vm.completedPrayersToday.length}/5 Kılındı',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: vm.syncAllWithLivePrayerTimes,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Hizala',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _prayerChip(vm, 'Sabah', p.fajr, prayerKey: 'Fajr'),
              _prayerChip(vm, 'Güneş', p.sunrise),
              _prayerChip(vm, 'Öğle', p.dhuhr, prayerKey: 'Dhuhr'),
              _prayerChip(vm, 'İkindi', p.asr, prayerKey: 'Asr'),
              _prayerChip(vm, 'Akşam', p.maghrib, prayerKey: 'Maghrib'),
              _prayerChip(vm, 'Yatsı', p.isha, prayerKey: 'Isha'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prayerChip(
    PlannerViewModel vm,
    String label,
    String time, {
    String? prayerKey,
  }) {
    final isDone =
        prayerKey != null && vm.isPrayerCompletedToday(prayerKey);
    return GestureDetector(
      onTap: prayerKey != null
          ? () => vm.togglePrayerCompleted(prayerKey)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDone
                        ? const Color(0xFF15803D)
                        : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                if (isDone) ...[
                  const SizedBox(width: 3),
                  const AppSvgIcon(
                    svgData: AppSvgs.checkCircle,
                    size: 10,
                    color: Color(0xFF15803D),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                color: isDone
                    ? const Color(0xFF14532D)
                    : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHealthSummaryStrip(PlannerViewModel vm) {
    final water = vm.activeWaterTracker;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const AppSvgIcon(
              svgData: AppSvgs.waterDrop,
              color: Color(0xFF0284C7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Su: ${water.currentIntakeMl}/${water.dailyGoalMl} ml',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 16,
              color: const Color(0xFFE2E8F0),
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            const AppSvgIcon(
              svgData: AppSvgs.pillCapsule,
              color: Color(0xFF0F766E),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'İlaç: ${vm.takenMedicationCount}/${vm.medicationReminders.length} Alındı',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Text(
              'Aç',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F766E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(PlannerViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _filterPill(vm, 'all', 'Tümü (${vm.allBlocks.length})'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterPill(
            vm,
            'personal',
            'Kişisel (${vm.personalBlocksOnly.length})',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterPill(
            vm,
            'shared',
            'Ortak (${vm.sharedBlocksOnly.length})',
          ),
        ),
      ],
    );
  }

  Widget _filterPill(PlannerViewModel vm, String value, String label) {
    final selected = vm.timelineFilter == value;
    return GestureDetector(
      onTap: () => vm.setTimelineFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleBlockCard(
    BuildContext context,
    PlannerViewModel vm,
    ScheduleBlock block,
  ) {
    final isShared = block.isSharedPlan;
    final badgeColor = isShared
        ? const Color(0xFF0F766E)
        : const Color(0xFF334155);

    final statusBadge = switch (block.status) {
      'checked_in' => (
        'Derste / Başladı',
        const Color(0xFF0284C7),
        const Color(0xFFE0F2FE),
      ),
      'completed' => (
        'Tamamlandı',
        const Color(0xFF15803D),
        const Color(0xFFDCFCE7),
      ),
      'skipped' => (
        'Atlandı',
        const Color(0xFFB91C1C),
        const Color(0xFFFEE2E2),
      ),
      _ => ('Planlandı', const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };

    final isRinging = vm.isReminderActiveFor(block.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _minimalCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: Time + Visibility badge (Kişisel Plan vs Ortak Plan) + Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppSvgIcon(
                        svgData: AppSvgs.clock,
                        size: 13,
                        color: Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${block.startTime} - ${block.endTime}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon(
                        svgData: isShared
                            ? AppSvgs.usersCouple
                            : AppSvgs.userSingle,
                        size: 11,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        block.ownerLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBadge.$3,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      statusBadge.$1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusBadge.$2,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          decoration: block.status == 'skipped'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (block.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          block.description,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Planı Düzenle',
                  onPressed: () => _openBlockEditor(context, vm, block),
                  icon: const AppSvgIcon(
                    svgData: AppSvgs.sliders,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            // Feature tags (Prayer anchor, Voice reminder, Phone lock)
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (block.isPrayerAnchored)
                  _featureTag(
                    svg: AppSvgs.prayerCrescent,
                    text:
                        'Canlı Namaz Vakti (${block.prayerOffsetMinutes == 0 ? "Tam Vakit" : "+${block.prayerOffsetMinutes} dk"})',
                    color: const Color(0xFF0F766E),
                  ),
                if (block.voiceReminderEnabled)
                  _featureTag(
                    svg: AppSvgs.bellNotification,
                    text:
                        '${block.remindBeforeMinutes} dk kala • ${block.repeatCount}x Tekrarlı Alarm',
                    color: const Color(0xFF4F46E5),
                  ),
                if (block.phoneLockEnabled)
                  _featureTag(
                    svg: AppSvgs.shieldLock,
                    text: 'Telefon Kısıtlama (Sadece Arama)',
                    color: const Color(0xFFB45309),
                  ),
              ],
            ),

            // Sub-task checklist items
            if (block.checklistItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sonraki İşten Önce Yapılacaklar (Tik Listesi)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...block.checklistItems.map(
                      (item) => InkWell(
                        onTap: () => vm.toggleChecklistItem(block, item.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(
                                item.done
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                size: 18,
                                color: item.done
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: const Color(0xFF1E293B),
                                    decoration: item.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (block.completionNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      svgData: AppSvgs.noteSummary,
                      size: 16,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ders/Görev Özeti: ${block.completionNotes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (block.status == 'skipped' && block.skipReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      svgData: AppSvgs.alertCircle,
                      size: 16,
                      color: Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atlama Nedeni: ${block.skipReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (block.status == 'planned')
                  FilledButton.tonal(
                    onPressed: () => vm.checkInToBlock(block),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      isRinging
                          ? 'Derse Geldim (Alarmı Sustur)'
                          : 'Derse Geldim / Başladım',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                OutlinedButton(
                  onPressed: () =>
                      _openCompletionReviewSheet(context, vm, block),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Bitti (Neler Yaptım) / Atla',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (block.status == 'planned')
                  TextButton(
                    onPressed: () => vm.shiftBlockByMinutes(block, 15),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      '+15 dk Kaydır',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (block.voiceReminderEnabled)
                  TextButton(
                    onPressed: () => vm.triggerVoiceReminderNow(block),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Alarmı Çaldır',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (block.phoneLockEnabled)
                  TextButton(
                    onPressed: () => vm.activatePhoneLockdownShield(
                      title:
                          '${block.title} (${block.startTime} - ${block.endTime})',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Kısıtlamayı Aç',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTag({
    required String svg,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(svgData: svg, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ORTAK İŞLERİMİZ & PARTNER BAĞLANTISI (@KULLANICI_ADI EKOSİSTEMİ, SIFIR MAİL)
  // ===========================================================================
  Widget _buildSharedPlansAndPartnersTab(
    BuildContext context,
    PlannerViewModel vm,
  ) {
    final sharedList = vm.sharedBlocksOnly;
    final partnersText = vm.linkedPartnerNames.isEmpty
        ? 'Aktif Ortak Yok'
        : vm.linkedPartnerNames.join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
      children: [
        // Membership, Privacy & Partner Connection Card (@username only, zero email!)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _minimalCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppSvgIcon(
                      svgData: AppSvgs.usersCouple,
                      color: Color(0xFF0F766E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ortak Partner: $partnersText (${vm.primaryPartnerHandle})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Üye: ${vm.activeDisplayName} (${vm.activeUsernameHandle}) • Kod: ${vm.familyProfile.inviteCode}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      svgData: AppSvgs.shieldLock,
                      color: Color(0xFF0F766E),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sıfır Şahsi Veri & Gizlilik Koruması: E-posta veya telefon numarası asla görünmez. Sizin ${vm.personalBlocksOnly.length} kişisel planınız yalnızca bu cihazda görünür; ${vm.primaryPartnerHandle} ile sadece aşağıdaki ${sharedList.length} ortak plan paylaşılır.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Direct Partner Connections Lifecycle Management (Pause / Unlink / Approve / Delete)
              const Text(
                'Ortak Bağlantı & Partner Yönetimi (@kullanici_adi)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              if (vm.partnerInvitations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Aktif ortak bağlantı bulunmuyor. Kişisel planlarınız yalnız size özeldir.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: vm.reconnectDefaultPartner,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFDCFCE7),
                          foregroundColor: const Color(0xFF15803D),
                        ),
                        child: Text(
                          '${vm.primaryPartnerHandle} Bağla',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...vm.partnerInvitations.map((inv) {
                  final isAccepted = inv.status == 'accepted';
                  final isPaused = inv.status == 'paused' || inv.sharingPaused;
                  final statusText = isPaused
                      ? 'Paylaşım Duraklatıldı'
                      : isAccepted
                      ? 'Bağlı & Aktif'
                      : 'Onay Bekliyor';
                  final statusColor = isPaused
                      ? const Color(0xFFB45309)
                      : isAccepted
                      ? const Color(0xFF15803D)
                      : const Color(0xFF0284C7);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.partnerDisplayFor(vm.activeUsername),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    inv.relationshipType,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (inv.status == 'pending')
                              FilledButton.tonal(
                                onPressed: () => vm
                                    .acceptOrReconnectPartnerInvitation(inv),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: const Color(0xFFDCFCE7),
                                  foregroundColor: const Color(0xFF15803D),
                                ),
                                child: const Text(
                                  'Bağlantıyı Onayla',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            if (isAccepted || isPaused)
                              OutlinedButton(
                                onPressed: () =>
                                    vm.togglePausePartnerSharing(inv),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: const Color(0xFF0F172A),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  isPaused
                                      ? 'Paylaşımı Sürdür'
                                      : 'Paylaşımı Duraklat',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            OutlinedButton(
                              onPressed: () =>
                                  vm.removeOrUnlinkPartnerConnection(inv),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: const Color(0xFFB91C1C),
                                side: const BorderSide(
                                  color: Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                isAccepted || isPaused
                                    ? 'Bağlantıyı Kaldır / Sil'
                                    : 'Daveti İptal Et / Sil',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _openAuthAndInviteModal(context, vm),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '@kullanici_adi İle Partner Davet & Hesap Yönetimi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cupla & TimeTree Benchmark: Shared Household Chores, Shopping & Partner Notes Board
        Container(
          padding: const EdgeInsets.all(15),
          decoration: _minimalCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppSvgIcon(
                    svgData: AppSvgs.noteSummary,
                    color: Color(0xFF0F766E),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ortak Ev & Alışveriş (${vm.sharedChoresAndNotes.length})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _openAddSharedChoreNoteDialog(context, vm),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF0F766E),
                    ),
                    icon: const AppSvgIcon(
                      svgData: AppSvgs.plus,
                      color: Color(0xFF0F766E),
                      size: 14,
                    ),
                    label: const Text(
                      'Not Ekle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (vm.sharedChoresAndNotes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Market alışverişi, kargo takibi veya eşinize anlık not ekleyin.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                )
              else
                ...vm.sharedChoresAndNotes.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: item.isDone
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: item.isDone
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => vm.toggleSharedChoreOrNote(item),
                          child: Icon(
                            item.isDone
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: item.isDone
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.categoryLabel} • Ekleyen: ${item.formattedAuthorHandle} • Sorumlu: ${item.assignedTo}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.id != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                vm.deleteSharedChoreOrNote(item.id!),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$partnersText İle Ortak Planlarımız (${sharedList.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const ValueKey('add_shared_block_btn'),
              onPressed: () =>
                  _openBlockEditor(context, vm, null, initialShared: true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const AppSvgIcon(
                svgData: AppSvgs.plus,
                color: Colors.white,
                size: 13,
              ),
              label: const Text(
                'Ortak Plan Ekle',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sharedList.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _minimalCardDecoration(),
            child: const Text(
              'Henüz ortak işaretlenmiş bir plan bulunmuyor veya ortak paylaşım duraklatıldı.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          )
        else
          ...sharedList.map(
            (block) => _buildScheduleBlockCard(context, vm, block),
          ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: İLAÇ HATIRLATICI & SU HATIRLATICI + CİHAZ BİLDİRİMLERİ
  // ===========================================================================
  Widget _buildHealthWaterAndMedicationsTab(
    BuildContext context,
    PlannerViewModel vm,
  ) {
    final water = vm.activeWaterTracker;
    final meds = vm.medicationReminders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        // OS Notification Permission Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _minimalCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppSvgIcon(
                  svgData: AppSvgs.bellNotification,
                  color: Color(0xFF0F766E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.deviceNotificationsGranted
                          ? 'Cihaz Bildirim İzni Aktif (iOS & Android)'
                          : 'Cihaz Bildirim İzni Bekleniyor',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'İlaç, su ve ders hatırlatmaları doğrudan telefon bildirim merkezine gönderilir',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: vm.requestDeviceNotificationPermissions,
                child: const Text(
                  'İzin Kontrol',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // WATER TRACKER CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _minimalCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppSvgIcon(
                      svgData: AppSvgs.waterDrop,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişisel Su Hatırlatıcım (${vm.activeUsernameHandle})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Her ${water.reminderIntervalMinutes} dakikada bir cihaz bildirimi • ${water.completedCups}/${water.totalGoalCups} Bardak',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openWaterGoalDialog(context, vm),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${water.currentIntakeMl} / ${water.dailyGoalMl} ml',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const Text(
                            'Hedefi Düzenle',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: water.progressRatio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => vm.addWaterIntake(250),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '+250 ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => vm.addWaterIntake(500),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '+500 ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: water.currentIntakeMl > 0
                        ? () => vm.addWaterIntake(-250)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '-250 ml',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: vm.triggerWaterDeviceNotificationNow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Hatırlat',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // MEDICATION REMINDERS SECTION
        Row(
          children: [
            const AppSvgIcon(
              svgData: AppSvgs.pillCapsule,
              color: Color(0xFF0F766E),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'İlaç & Vitaminlerim (${meds.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAddMedicationDialog(context, vm),
              icon: const AppSvgIcon(
                svgData: AppSvgs.plus,
                color: Color(0xFF0F766E),
                size: 15,
              ),
              label: const Text(
                'Yeni İlaç Ekle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...meds.map((med) => _buildMedicationCard(vm, med)),
      ],
    );
  }

  Widget _buildMedicationCard(PlannerViewModel vm, MedicationReminder med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _minimalCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => vm.toggleMedicationTaken(med),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: med.takenToday
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon(
                    svgData: med.takenToday
                        ? AppSvgs.checkCircle
                        : AppSvgs.pillCapsule,
                    color: med.takenToday
                        ? const Color(0xFF15803D)
                        : const Color(0xFF475569),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            med.medicationName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              decoration: med.takenToday
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            med.ownerLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Saat ${med.reminderTime} • ${med.dosage} • ${med.mealRelation}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                if (med.id != null)
                  TextButton(
                    onPressed: () => vm.deleteMedicationReminder(med.id!),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: const Color(0xFFB91C1C),
                    ),
                    child: const Text(
                      'İlacı Sil',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => vm.sendMedicationDeviceNotification(med),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: const Color(0xFF0F766E),
                  ),
                  icon: const AppSvgIcon(
                    svgData: AppSvgs.bellNotification,
                    color: Color(0xFF0F766E),
                    size: 14,
                  ),
                  label: const Text(
                    'Cihaza Bildir',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => vm.toggleMedicationTaken(med),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: med.takenToday
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFF0F172A),
                    foregroundColor: med.takenToday
                        ? const Color(0xFF166534)
                        : Colors.white,
                  ),
                  child: Text(
                    med.takenToday ? 'İçildi (Tamam)' : 'İçildi İşaretle',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: TELEFON KISITLAMA & ODAK KALKANI (SADECE ARAMALAR)
  // ===========================================================================
  Widget _buildFocusLockdownTab(BuildContext context, PlannerViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppSvgIcon(
                    svgData: AppSvgs.shieldLock,
                    color: Color(0xFF38BDF8),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Telefon Kısıtlama & Odak Kalkanı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Belirlediğiniz saatler arasında telefonu kullanım dışı bırakır. '
                'Yalnızca gelen telefon aramalarına cevap verebilir veya acil durumda eşinizi arayabilirsiniz.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => vm.activatePhoneLockdownShield(
                    title: 'Odak Saati (Sadece Aramalar Açık)',
                  ),
                  child: const Text(
                    'Şimdi Telefon Kısıtlama Modunu Başlat',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Planlı Kısıtlama Saatleri',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAddFocusRuleDialog(context, vm),
              icon: const AppSvgIcon(
                svgData: AppSvgs.plus,
                color: Color(0xFF0F766E),
                size: 14,
              ),
              label: const Text(
                'Yeni Kural Ekle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...vm.focusSessions.map(
          (session) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: _minimalCardDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${session.startTime} - ${session.endTime} • Sadece Aramalar Serbest',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (session.id != null)
                  TextButton(
                    onPressed: () => vm.deleteFocusSession(session.id!),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFB91C1C),
                    ),
                    child: const Text(
                      'Sil',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Switch(
                  value: session.isActive,
                  onChanged: (_) => vm.toggleFocusSession(session),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 5: TAKİP, DERS ÖZETLERİ & ATLANAN DERSLER
  // ===========================================================================
  Widget _buildAnalyticsAndSkippedTab(
    BuildContext context,
    PlannerViewModel vm,
  ) {
    final completedBlocks = vm.allBlocks
        .where((b) => b.status == 'completed' || b.completionNotes.isNotEmpty)
        .toList();
    final skippedBlocks = vm.allBlocks
        .where((b) => b.status == 'skipped')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'Tamamlanan',
                value: '${vm.completedCount}',
                color: const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Aktif / Derste',
                value: '${vm.checkedInCount}',
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Atlanan',
                value: '${vm.skippedCount}',
                color: const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Ders & İş Sonu Neler Yapıldı? (Tamamlanan Notlar)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        if (completedBlocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _minimalCardDecoration(),
            child: const Text(
              'Henüz tamamlanan ders/iş özeti girilmedi.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          )
        else
          ...completedBlocks.map(
            (b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: _minimalCardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSvgIcon(
                    svgData: AppSvgs.checkCircle,
                    color: Color(0xFF15803D),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.title} (${b.startTime} - ${b.endTime})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          b.completionNotes.isEmpty
                              ? 'Tüm alt maddeler tamamlandı.'
                              : b.completionNotes,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => vm.resetBlockToPlanned(b),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF475569),
                    ),
                    child: const Text(
                      'Sıfırla',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Atlanan / Gidilmeyen Ders & Plan Takibi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        if (skippedBlocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _minimalCardDecoration(),
            child: const Text(
              'Harika! Bugün hiçbir ders veya plan atlanmadı.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          )
        else
          ...skippedBlocks.map(
            (b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: _minimalCardDecoration(),
              child: Row(
                children: [
                  const AppSvgIcon(
                    svgData: AppSvgs.alertCircle,
                    color: Color(0xFFB91C1C),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.title} (${b.startTime} - ${b.endTime})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Neden: ${b.skipReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => vm.resetBlockToPlanned(b),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Tekrar Planla',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => vm.checkInToBlock(b),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Telafi Et',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: _minimalCardDecoration(),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _minimalCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  void _openAuthAndInviteModal(BuildContext context, PlannerViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthAndInviteSheet(viewModel: vm),
    );
  }

  void _openBlockEditor(
    BuildContext context,
    PlannerViewModel vm,
    ScheduleBlock? existing, {
    bool initialShared = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlockEditorSheet(
        familyId: vm.familyProfile.id,
        planDate: vm.formattedSelectedDate,
        personalRoleKey: vm.memberRoleKey,
        initialShared: initialShared,
        existingBlock: existing,
        onSave: vm.saveOrCreateBlock,
        onDelete: existing?.id != null
            ? () => vm.deleteBlock(existing!.id!)
            : null,
      ),
    );
  }

  void _openWaterGoalDialog(BuildContext context, PlannerViewModel vm) {
    final goalCtrl = TextEditingController(
      text: '${vm.activeWaterTracker.dailyGoalMl}',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günlük Su Hedefi (ml)'),
        content: TextField(
          controller: goalCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef Miktar (Örn: 2500 veya 3000 ml)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(goalCtrl.text.trim()) ?? 2500;
              vm.updateWaterDailyGoal(parsed);
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _openAddFocusRuleDialog(BuildContext context, PlannerViewModel vm) {
    final titleCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '21:00');
    final endCtrl = TextEditingController(text: '22:30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Telefon Kısıtlama Kuralı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Kural Adı (Örn: Akşam Kitap & Aile Vakti)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(
                labelText: 'Başlangıç Saati (SS:DD)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(
                labelText: 'Bitiş Saati (SS:DD)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              vm.addFocusSession(
                FocusSession(
                  familyId: vm.familyProfile.id,
                  targetRole: vm.memberRoleKey,
                  title: titleCtrl.text.trim(),
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  allowCallsOnly: true,
                  isActive: true,
                  emergencyContactPhone: '+90 555 000 00 00',
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _openCompletionReviewSheet(
    BuildContext context,
    PlannerViewModel vm,
    ScheduleBlock block,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CompletionReviewSheet(
        block: block,
        onComplete: (notes, items) => vm.completeBlockWithSummary(
          block: block,
          completionNotes: notes,
          updatedChecklist: items,
        ),
        onSkip: (reason) =>
            vm.skipBlockWithReason(block: block, skipReason: reason),
      ),
    );
  }

  void _openAddMedicationDialog(BuildContext context, PlannerViewModel vm) {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController(text: '1 Kapsül');
    final timeCtrl = TextEditingController(text: '13:00');
    String mealRelation = 'Tok Karnına';
    String ownerRole = vm.memberRoleKey;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni İlaç / Vitamin Hatırlatıcı'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'İlaç / Takviye Adı (Örn: B12 Vitamini)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: doseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dozaj (Örn: 1 Tablet)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hatırlatma Saati (SS:DD)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: mealRelation,
                  decoration: const InputDecoration(
                    labelText: 'Kullanım Şekli',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Tok Karnına',
                      child: Text('Tok Karnına'),
                    ),
                    DropdownMenuItem(
                      value: 'Aç Karnına',
                      child: Text('Aç Karnına'),
                    ),
                    DropdownMenuItem(
                      value: 'Bol Su İle',
                      child: Text('Bol Su İle'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => mealRelation = v);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: ownerRole,
                  decoration: const InputDecoration(
                    labelText: 'Görünürlük & Gizlilik',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: vm.memberRoleKey,
                      child: const Text('Kişisel (Sadece Ben Görürüm)'),
                    ),
                    const DropdownMenuItem(
                      value: 'shared',
                      child: Text('Ortak Hatırlatıcı (Beraber Görülür)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => ownerRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                vm.addMedicationReminder(
                  MedicationReminder(
                    familyId: vm.familyProfile.id,
                    ownerRole: ownerRole,
                    medicationName: nameCtrl.text.trim(),
                    dosage: doseCtrl.text.trim(),
                    reminderTime: timeCtrl.text.trim(),
                    mealRelation: mealRelation,
                    takenToday: false,
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Kaydet & Bildirim Kur'),
            ),
          ],
        ),
      ),
    );
  }

  void _openFamilySettingsDialog(BuildContext context, PlannerViewModel vm) {
    final cityCtrl = TextEditingController(text: vm.familyProfile.city);
    final wakeCtrl = TextEditingController(text: vm.familyProfile.wakeUpTime);
    final sleepCtrl = TextEditingController(text: vm.familyProfile.sleepTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rutin & Namaz Şehri Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(
                labelText: 'Namaz Vakti Şehri (Örn: Istanbul, Ankara)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: wakeCtrl,
              decoration: const InputDecoration(
                labelText: 'Günlük Uyanış Saati (Örn: 05:00)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sleepCtrl,
              decoration: const InputDecoration(
                labelText: 'Günlük Uyku Saati (Örn: 23:00)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              vm.updateFamilySettings(
                city: cityCtrl.text.trim(),
                wakeUpTime: wakeCtrl.text.trim(),
                sleepTime: sleepCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _openAddSharedChoreNoteDialog(
    BuildContext context,
    PlannerViewModel vm,
  ) {
    final titleCtrl = TextEditingController();
    String category = 'shopping';
    String assignedTo = vm.primaryPartnerHandle;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ortak Ev, Alışveriş & Eşe Not Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Not veya İhtiyaç (Örn: Dönüşte süt ve ekmek al)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: const [
                    DropdownMenuItem(
                      value: 'shopping',
                      child: Text('Market & Alışveriş'),
                    ),
                    DropdownMenuItem(
                      value: 'note',
                      child: Text('Eşe Anlık Not / Hatırlatma'),
                    ),
                    DropdownMenuItem(
                      value: 'chore',
                      child: Text('Ev & Sorumluluk'),
                    ),
                    DropdownMenuItem(
                      value: 'date_idea',
                      child: Text('Birlikte Etkinlik / Kahvaltı Planı'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: assignedTo,
                  decoration: const InputDecoration(
                    labelText: 'Sorumlu (@kullanici_adi)',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: vm.primaryPartnerHandle,
                      child: Text('Eşim / Partnerim (${vm.primaryPartnerHandle})'),
                    ),
                    DropdownMenuItem(
                      value: vm.activeUsernameHandle,
                      child: Text('Ben (${vm.activeUsernameHandle})'),
                    ),
                    const DropdownMenuItem(
                      value: 'Ortak',
                      child: Text('Ortak (İkimiz Beraber)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => assignedTo = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                vm.addSharedChoreOrNote(
                  title: titleCtrl.text.trim(),
                  category: category,
                  assignedTo: assignedTo,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Panoya Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSpiritualWidgetSheet(BuildContext context, PlannerViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpiritualWidgetCustomizerSheet(viewModel: vm),
    );
  }
}
