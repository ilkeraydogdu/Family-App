import 'package:flutter/material.dart';

import '../../domain/models/family_models.dart';
import '../view_models/planner_view_model.dart';
import '../widgets/block_editor_sheet.dart';
import '../widgets/completion_review_sheet.dart';
import 'phone_lockdown_shield_view.dart';

class HomeShellView extends StatefulWidget {
  final PlannerViewModel viewModel;

  const HomeShellView({super.key, required this.viewModel});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _selectedTabIndex = 0;

  PlannerViewModel get vm => widget.viewModel;

  void _openBlockEditor({ScheduleBlock? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlockEditorSheet(
        familyId: vm.familyProfile.id,
        planDate: vm.formattedSelectedDate,
        existingBlock: existing,
        onSave: vm.saveOrCreateBlock,
      ),
    );
  }

  void _openCompletionSheet(ScheduleBlock block) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CompletionReviewSheet(
        block: block,
        onComplete: (notes, checklist) {
          vm.completeBlockWithSummary(
            block: block,
            completionNotes: notes,
            updatedChecklist: checklist,
          );
        },
        onSkip: (reason) {
          vm.skipBlockWithReason(block: block, skipReason: reason);
        },
      ),
    );
  }

  void _openFamilySettingsDialog() {
    final cityCtrl = TextEditingController(text: vm.familyProfile.city);
    final wakeCtrl = TextEditingController(text: vm.familyProfile.wakeUpTime);
    final sleepCtrl = TextEditingController(text: vm.familyProfile.sleepTime);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aile & Namaz Vakti Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(
                labelText: 'Şehir (Canlı Diyanet Namaz Vakti İçin)',
                hintText: 'Istanbul, Ankara, Izmir, Eskisehir...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: wakeCtrl,
              decoration: const InputDecoration(
                labelText: 'Ortak Uyanış Hedefi (Örn: 05:00)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sleepCtrl,
              decoration: const InputDecoration(
                labelText: 'Ortak Uyku Hedefi (Örn: 23:00)',
                border: OutlineInputBorder(),
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
                city: cityCtrl.text.trim().isEmpty
                    ? 'Istanbul'
                    : cityCtrl.text.trim(),
                wakeUpTime: wakeCtrl.text.trim().isEmpty
                    ? '05:00'
                    : wakeCtrl.text.trim(),
                sleepTime: sleepCtrl.text.trim().isEmpty
                    ? '23:00'
                    : sleepCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet & Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isPhoneLockShieldActive) {
          return PhoneLockdownShieldView(
            reasonTitle: vm.activeLockdownReason,
            onExitLockdown: vm.deactivatePhoneLockdownShield,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1B4B),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vm.familyProfile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Kod: ${vm.familyProfile.inviteCode}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Uyanış: ${vm.familyProfile.wakeUpTime} • Uyku: ${vm.familyProfile.sleepTime} • ${vm.familyProfile.city}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ActionChip(
                  backgroundColor: vm.activeUserRole == 'husband'
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFEC4899),
                  avatar: const Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    vm.activeUserRole == 'husband'
                        ? 'Aktif: İlker'
                        : 'Aktif: Eşim',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    final nextRole = vm.activeUserRole == 'husband'
                        ? 'wife'
                        : 'husband';
                    vm.switchActivePersonRole(nextRole);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Şehir & Uyku Saatleri',
                onPressed: _openFamilySettingsDialog,
                icon: const Icon(Icons.tune),
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
                        color: Colors.amber.shade900,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.record_voice_over,
                              color: Colors.white,
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
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.amber.shade900,
                              ),
                              onPressed: vm.stopAllVoiceReminders,
                              child: const Text('Sustur'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          _buildDailyTimelineTab(),
                          _buildCoupleComparisonTab(),
                          _buildFocusLockdownTab(),
                          _buildStatsAndTrackingTab(),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: _selectedTabIndex <= 1
              ? FloatingActionButton.extended(
                  onPressed: () => _openBlockEditor(),
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Saatlik Plan Ekle'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (idx) =>
                setState(() => _selectedTabIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule),
                label: 'Günlük Ajanda',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Ben & Eşim',
              ),
              NavigationDestination(
                icon: Icon(Icons.phonelink_lock_outlined),
                selectedIcon: Icon(Icons.phonelink_lock),
                label: 'Odak & Kilit',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Takip & Özet',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyTimelineTab() {
    final p = vm.prayerTimes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Live Prayer Times Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.mosque,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Canlı Namaz Vakitleri (${p.city})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: vm.syncAllWithLivePrayerTimes,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync, color: Colors.amberAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Saatleri Vakte Hizala',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _prayerPill('Sabah', p.fajr),
                  _prayerPill('Güneş', p.sunrise),
                  _prayerPill('Öğle', p.dhuhr),
                  _prayerPill('İkindi', p.asr),
                  _prayerPill('Akşam', p.maghrib),
                  _prayerPill('Yatsı', p.isha),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Date & Filter Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all', 'Ortak Akış (İkimiz)', Icons.people),
              const SizedBox(width: 8),
              _filterChip('husband', 'İlker\'in Planı', Icons.person),
              const SizedBox(width: 8),
              _filterChip('wife', 'Eşimin Planı', Icons.person_2),
              const SizedBox(width: 8),
              _filterChip('shared', 'Sadece Ortak', Icons.favorite),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...vm.filteredBlocks.map(_buildScheduleBlockCard),
      ],
    );
  }

  Widget _prayerPill(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label, IconData icon) {
    final selected = vm.timelineFilter == key;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : const Color(0xFF1E1B4B),
      ),
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF1E1B4B),
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => vm.setTimelineFilter(key),
    );
  }

  Widget _buildScheduleBlockCard(ScheduleBlock block) {
    final isHusband = block.ownerRole == 'husband';
    final isWife = block.ownerRole == 'wife';
    final accentColor = isHusband
        ? const Color(0xFF4F46E5)
        : isWife
        ? const Color(0xFFDB2777)
        : const Color(0xFF0D9488);

    Color statusBg = Colors.grey.shade100;
    Color statusText = Colors.grey.shade800;
    if (block.status == 'checked_in') {
      statusBg = Colors.blue.shade50;
      statusText = Colors.blue.shade800;
    } else if (block.status == 'completed') {
      statusBg = Colors.green.shade50;
      statusText = Colors.green.shade800;
    } else if (block.status == 'skipped') {
      statusBg = Colors.red.shade50;
      statusText = Colors.red.shade800;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: block.status == 'checked_in'
              ? Colors.blue.shade400
              : Colors.grey.shade200,
          width: block.status == 'checked_in' ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Time + Owner Badge + Status Badge + Edit
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${block.startTime} - ${block.endTime}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    block.ownerLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    block.statusLabel,
                    style: TextStyle(
                      color: statusText,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _openBlockEditor(existing: block),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              block.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: block.status == 'skipped'
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (block.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                block.description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            // Feature Badges (Prayer Anchored, Voice Reminder, Phone Lock)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (block.isPrayerAnchored)
                  _infoBadge(
                    Icons.mosque,
                    'Canlı ${PrayerTimesDay.turkishPrayerName(block.prayerName)} Vaktine Bağlı',
                    Colors.teal.shade700,
                  ),
                if (block.voiceReminderEnabled)
                  _infoBadge(
                    Icons.record_voice_over,
                    '${block.remindBeforeMinutes} dk kala • ${block.repeatCount} kez sesli tekrar',
                    Colors.deepPurple.shade700,
                  ),
                if (block.phoneLockEnabled)
                  _infoBadge(
                    Icons.phonelink_lock,
                    'Telefon Kısıtlı (Sadece Aramalar)',
                    Colors.amber.shade900,
                  ),
              ],
            ),
            // Checklist ("tık attığı yer")
            if (block.checklistItems.isNotEmpty) ...[
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alt Görevler (${block.completedChecklistCount}/${block.checklistItems.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: item.done ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
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
            if (block.completionNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '📝 Ders/Görev Sonu Özeti: ${block.completionNotes}',
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (block.status == 'skipped' && block.skipReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⚠️ Atlama Nedeni: ${block.skipReason}',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Divider(height: 18),
            // Action Buttons Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (block.status == 'planned')
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade800,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => vm.checkInToBlock(block),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Derse Geldim / Başladım'),
                    ),
                  if (block.status == 'planned') const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _openCompletionSheet(block),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: const Text('Ders Bitti Özeti / Atladım'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => vm.triggerVoiceReminderNow(block),
                    icon: const Icon(Icons.volume_up, size: 16),
                    label: const Text('Sesli Hatırlat'),
                  ),
                  if (block.phoneLockEnabled) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.amber.shade900,
                      ),
                      onPressed: () => vm.activatePhoneLockdownShield(
                        title:
                            '${block.title} (${block.startTime} - ${block.endTime})',
                      ),
                      icon: const Icon(Icons.lock_clock, size: 16),
                      label: const Text('Kilitle'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleComparisonTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFF4F46E5)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yan Yana Eş Görünümü: Senin ve eşinin aynı saatlerdeki kişisel ve ortak planlarını tek ekranda karşılaştırabilirsin.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPersonColumn(
                title: 'İlker\'in Günü',
                color: const Color(0xFF4F46E5),
                blocks: vm.husbandBlocks,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPersonColumn(
                title: 'Eşimin Günü',
                color: const Color(0xFFDB2777),
                blocks: vm.wifeBlocks,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonColumn({
    required String title,
    required Color color,
    required List<ScheduleBlock> blocks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...blocks.map(
          (b) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${b.startTime} - ${b.endTime}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.statusLabel,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusLockdownTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.phonelink_lock, color: Colors.amber, size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Telefon Kısıtlama & Sadece Aramalar Modu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Belirlediğiniz saatler arasında telefonu kullanım dışı bırakır; sadece eşinizden veya acil numaralardan gelen aramalara cevap vermenize izin verir.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => vm.activatePhoneLockdownShield(),
                  icon: const Icon(Icons.shield),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Kısıtlama Kalkanını Şimdi Başlat (Test Et)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Planlı Telefon Kısıtlama Saatleri',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...vm.focusSessions.map(
          (session) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: SwitchListTile(
              value: session.isActive,
              onChanged: (_) => vm.toggleFocusSession(session),
              title: Text(
                session.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Saat: ${session.startTime} - ${session.endTime} • Sadece Aramalar Açık',
              ),
              secondary: const Icon(Icons.phone_callback, color: Colors.indigo),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsAndTrackingTab() {
    final completedBlocks = vm.allBlocks
        .where((b) => b.status == 'completed')
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
              child: _statCard(
                'Tamamlanan',
                '${vm.completedCount}',
                Colors.green.shade700,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'Derste / Aktif',
                '${vm.checkedInCount}',
                Colors.blue.shade700,
                Icons.play_circle_fill,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'Atlanan',
                '${vm.skippedCount}',
                Colors.red.shade700,
                Icons.event_busy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Ders / İş Bitiminde Yazılan Özetler (Neler Yaptık?)',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (completedBlocks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Henüz tamamlanan ders/görev özeti yok. Bir plan üzerinde "Ders Bitti Özeti" butonuna tıklayarak neler yaptığını kaydedebilirsin.',
              ),
            ),
          )
        else
          ...completedBlocks.map(
            (b) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: Text(
                  '${b.title} (${b.startTime} - ${b.endTime}) • ${b.ownerLabel}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  b.completionNotes.isEmpty
                      ? 'Alt görevler tamamlandı (${b.completedChecklistCount}/${b.checklistItems.length})'
                      : b.completionNotes,
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Atlanan Dersler & Planlar Takibi',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (skippedBlocks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Harika! Bugün atlanan hiçbir ders veya plan yok.'),
            ),
          )
        else
          ...skippedBlocks.map(
            (b) => Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.red.shade800),
                title: Text(
                  '${b.title} (${b.startTime} - ${b.endTime}) • ${b.ownerLabel}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Atlama nedeni: ${b.skipReason}'),
                trailing: TextButton(
                  onPressed: () => vm.checkInToBlock(b),
                  child: const Text('Telafi Et'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
