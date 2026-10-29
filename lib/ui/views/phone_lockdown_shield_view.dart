import 'package:flutter/material.dart';

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
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phonelink_lock,
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'TELEFON KULLANIM DIŞI • SADECE ARAMALAR AÇIK',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 68,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.reasonTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belirlediğiniz saat aralığında sosyal medya ve bildirimler kısıtlandı. '
                    'Yalnızca gelen telefon aramalarına cevap verebilir veya eşinizi arayabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              if (_hasSimulatedIncomingCall)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _inActiveCall
                            ? 'Eşim ile Görüşme Devam Ediyor...'
                            : 'Gelen Arama: Eşim ❤️',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _inActiveCall
                            ? 'Kısıtlama modunda sesli arama izni aktif'
                            : 'Gelen aramaya izin verildi',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!_inActiveCall)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () =>
                                  setState(() => _inActiveCall = true),
                              icon: const Icon(Icons.call),
                              label: const Text('Cevapla'),
                            ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () => setState(() {
                              _hasSimulatedIncomingCall = false;
                              _inActiveCall = false;
                            }),
                            icon: const Icon(Icons.call_end),
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
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.greenAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _hasSimulatedIncomingCall = true),
                      icon: const Icon(Icons.ring_volume),
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
                    icon: const Icon(Icons.lock_open, color: Colors.white60),
                    label: const Text(
                      'Acil Durum: Kısıtlama Modundan Çık',
                      style: TextStyle(color: Colors.white60),
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
