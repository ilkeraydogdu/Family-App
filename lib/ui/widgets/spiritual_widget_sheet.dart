import 'package:flutter/material.dart';

import '../core/app_svg_icons.dart';
import '../view_models/planner_view_model.dart';

class DailySpiritualCard extends StatefulWidget {
  final PlannerViewModel viewModel;
  final VoidCallback onOpenWidgetCustomizer;

  const DailySpiritualCard({
    super.key,
    required this.viewModel,
    required this.onOpenWidgetCustomizer,
  });

  @override
  State<DailySpiritualCard> createState() => _DailySpiritualCardState();
}

class _DailySpiritualCardState extends State<DailySpiritualCard> {
  int _selectedSubTab = 0; // 0: Hadis-i Şerif, 1: Günün Duası & Ayeti, 2: Sabah/Akşam Zikri

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final content = vm.dailySpiritual;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppSvgIcon(
                  svgData: AppSvgs.prayerCrescent,
                  size: 16,
                  color: Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Günün Hadisi & Duası',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      content.isLiveFromOpenSource
                          ? 'Buhârî & Diyanet Canlı API'
                          : 'Günlük Manevi Rehber',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('open_widget_customizer_btn'),
                onPressed: widget.onOpenWidgetCustomizer,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Özel Widget',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 2),
              TextButton(
                key: const ValueKey('refresh_spiritual_btn'),
                onPressed: () => vm.refreshDailySpiritualFromOpenSource(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Yenile',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-Tab Selector (Hadis | Dua | Zikir)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabChip(0, 'Günün Hadisi'),
                ),
                Expanded(
                  child: _buildSubTabChip(1, 'Günün Duası'),
                ),
                Expanded(
                  child: _buildSubTabChip(2, 'Sabah/Akşam Zikri'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedSubTab == 0) ...[
            Text(
              '"${content.hadithText}"',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF8FAFC),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${content.hadithSource} • ${content.hadithNumber}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ] else if (_selectedSubTab == 1) ...[
            Text(
              content.duaArabic,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34D399),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"${content.duaTurkish}"',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF8FAFC),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              content.duaSource,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ] else ...[
            Text(
              content.morningEveningZikir,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF8FAFC),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubTabChip(int index, String label) {
    final selected = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class SpiritualWidgetCustomizerSheet extends StatefulWidget {
  final PlannerViewModel viewModel;

  const SpiritualWidgetCustomizerSheet({super.key, required this.viewModel});

  @override
  State<SpiritualWidgetCustomizerSheet> createState() =>
      _SpiritualWidgetCustomizerSheetState();
}

class _SpiritualWidgetCustomizerSheetState
    extends State<SpiritualWidgetCustomizerSheet> {
  late String _selectedStyle;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.viewModel.activeWidgetStyle;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final content = vm.dailySpiritual;
    final prayer = vm.prayerTimes;
    final nextBlock = vm.filteredBlocks
        .where((b) => b.status == 'planned')
        .firstOrNull;
    final nextPlanSummary = nextBlock != null
        ? 'Sıradaki: ${nextBlock.startTime} ${nextBlock.title}'
        : 'Tüm günlük planlar tamamlandı';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AppSvgIcon(
                    svgData: AppSvgs.prayerCrescent,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telefon Ana Ekran Özel Widget\'ları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Her gün açık kaynaktan çekilen Hadis, Dua ve Namaz vakitlerini telefon ana ekranında gösterir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('close_widget_sheet_btn'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Widget Style Selection
            const Text(
              'Widget Tasarımı Seçin:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            _buildStyleOption(
              styleId: 'hadith_dua',
              title: '1. Günün Hadisi & Duası Kartı (4x2 Büyük Widget)',
              subtitle:
                  'Sahîh-i Buhârî Hadisi + Kur\'an-ı Kerim Duası + Sıradaki Plan',
            ),
            const SizedBox(height: 8),
            _buildStyleOption(
              styleId: 'prayer_plan',
              title: '2. Namaz Vakitleri + Günün Duası + Ajanda (4x2 Widget)',
              subtitle:
                  'Canlı Diyanet Vakitleri + Günün Ayet Duası + Sıradaki Saatlik İş',
            ),
            const SizedBox(height: 8),
            _buildStyleOption(
              styleId: 'minimal_quote',
              title: '3. Minimal Kilit & Ana Ekran Hadis Widget (2x2 Kompakt)',
              subtitle: 'Sade koyu tema üzerinde günün hadis-i şerifi ve kaynağı',
            ),
            const SizedBox(height: 16),

            // Live Phone Home Screen Widget Preview
            const Text(
              'Canlı Telefon Ana Ekran Widget Önizlemesi:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedStyle == 'prayer_plan'
                        ? 'NAMAZ VAKİTLERİ • GÜNÜN DUASI & PLAN'
                        : _selectedStyle == 'minimal_quote'
                        ? 'GÜNÜN HADİS-İ ŞERİFİ'
                        : 'GÜNÜN HADİSİ & DUASI • AÇIK KAYNAK CANLI',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF34D399),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedStyle == 'prayer_plan'
                        ? content.duaTurkish
                        : content.hadithText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedStyle == 'prayer_plan'
                        ? 'Sabah ${prayer.fajr} • Öğle ${prayer.dhuhr} • İkindi ${prayer.asr} • Akşam ${prayer.maghrib}'
                        : _selectedStyle == 'minimal_quote'
                        ? '${content.hadithSource} (${content.hadithNumber})'
                        : 'Dua: ${content.duaTurkish} (${content.duaSource})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextPlanSummary,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      svgData: AppSvgs.checkCircle,
                      size: 16,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await vm.refreshDailySpiritualFromOpenSource();
                      setState(() {
                        _statusMessage =
                            'Açık kaynak API üzerinden yeni Hadis-i Şerif ve Kur\'an Duası çekildi.';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Farklı Hadis/Dua Çek',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('pin_home_widget_btn'),
                    onPressed: () async {
                      await vm.syncPhoneHomeScreenWidget(
                        styleOverride: _selectedStyle,
                        requestPin: true,
                      );
                      setState(() {
                        _statusMessage =
                            'Telefon ana ekran widget\'ı güncellendi ve bildirim merkezine sabitlendi!';
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ana Ekrana Sabitle',
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
    );
  }

  Widget _buildStyleOption({
    required String styleId,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedStyle == styleId;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = styleId),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            AppSvgIcon(
              svgData: selected ? AppSvgs.checkCircle : AppSvgs.clock,
              size: 18,
              color: selected
                  ? const Color(0xFF059669)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }
}
