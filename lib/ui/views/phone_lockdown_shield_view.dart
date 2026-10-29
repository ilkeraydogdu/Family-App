import 'package:flutter/material.dart';

import '../core/app_svg_icons.dart';

class PhoneLockdownShieldView extends StatefulWidget {
  final String reasonTitle;
  final VoidCallback onExitLockdown;

  const PhoneLockdownShieldView({
    super.key,
    required this.reasonTitle,
    required this.onExitLockdown,
  });

  @override
  State<PhoneLockdownShieldView> createState() =>
      _PhoneLockdownShieldViewState();
}

class _PhoneLockdownShieldViewState extends State<PhoneLockdownShieldView> {
  bool _hasSimulatedIncomingCall = false;
  bool _inActiveCall = false;

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          svgData: AppSvgs.shieldLock,
                          color: Color(0xFF38BDF8),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'TELEFON KULLANIM DIŞI • SADECE ARAMALAR AÇIK',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 68,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.reasonTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belirlediğiniz saat aralığında sosyal medya ve uygulama bildirimleri kısıtlandı. '
                    'Yalnızca gelen telefon aramalarına cevap verebilir veya acil durumda eşinizi arayabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              if (_hasSimulatedIncomingCall)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const AppSvgIcon(
                          svgData: AppSvgs.phoneCall,
                          color: Color(0xFF34D399),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _inActiveCall
                            ? 'Eşim ile Görüşme Devam Ediyor...'
                            : 'Gelen Arama: Eşim (Aile Hattı)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _inActiveCall
                            ? 'Kısıtlama modunda sesli arama izni aktif'
                            : 'Gelen aramaya izin verildi',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!_inActiveCall)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  setState(() => _inActiveCall = true),
                              icon: const AppSvgIcon(
                                svgData: AppSvgs.phoneCall,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text('Cevapla'),
                            ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => setState(() {
                              _hasSimulatedIncomingCall = false;
                              _inActiveCall = false;
                            }),
                            icon: const Icon(Icons.call_end, size: 18),
                            label: Text(_inActiveCall ? 'Bitir' : 'Reddet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF34D399),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _hasSimulatedIncomingCall = true),
                      icon: const AppSvgIcon(
                        svgData: AppSvgs.phoneCall,
                        color: Color(0xFF34D399),
                        size: 18,
                      ),
                      label: const Text(
                        'Gelen Arama Geldiğinde Nasıl Görünür? (Test Et)',
                      ),
                    ),
                  ],
                ),
              Column(
                children: [
                  TextButton.icon(
                    onPressed: widget.onExitLockdown,
                    icon: const Icon(
                      Icons.lock_open,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    label: const Text(
                      'Acil Durum: Kısıtlama Modundan Çık',
                      style: TextStyle(color: Color(0xFF94A3B8)),
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
