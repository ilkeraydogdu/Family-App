import 'package:flutter/material.dart';

import '../../core/config/supabase_config.dart';
import '../core/app_svg_icons.dart';
import '../view_models/planner_view_model.dart';

class AuthOnboardingView extends StatefulWidget {
  final PlannerViewModel viewModel;

  const AuthOnboardingView({super.key, required this.viewModel});

  @override
  State<AuthOnboardingView> createState() => _AuthOnboardingViewState();
}

class _AuthOnboardingViewState extends State<AuthOnboardingView> {
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorText;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(
    text: '@${SupabaseConfig.defaultHusbandUsername}',
  );
  final _passwordCtrl = TextEditingController(
    text: SupabaseConfig.defaultCouplePassword,
  );
  final _inviteCodeCtrl = TextEditingController(
    text: SupabaseConfig.defaultInviteCode,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final err = await widget.viewModel.registerOrLoginUser(
      isSignUp: _isSignUp,
      displayName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      inviteCode: _inviteCodeCtrl.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _isSubmitting = false;
        _errorText = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const AppSvgIcon(
                          svgData: AppSvgs.calendar,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hayat Düzeni & Ortak Ajanda',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'E-posta veya telefon paylaşmadan @kullanici_adi ile güvenli üyelik ve ortak plan ekosistemi.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mode Switch: Giriş Yap vs Yeni Üye Ol
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            selected: !_isSignUp,
                            label: 'Giriş Yap',
                            onTap: () => setState(() => _isSignUp = false),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            selected: _isSignUp,
                            label: 'Yeni Üye Ol',
                            onTap: () => setState(() => _isSignUp = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_errorText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isSignUp) ...[
                    TextField(
                      controller: _nameCtrl,
                      decoration: _inputDeco('Adınız Soyadınız'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailCtrl,
                    decoration: _inputDeco(
                      'Kullanıcı Adı (Örn: @ilker veya @neslihan)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: _inputDeco('Şifre'),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inviteCodeCtrl,
                      decoration: _inputDeco(
                        'Ortak Plan Davet Kodu (İsteğe Bağlı)',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? 'Oturum Açılıyor...'
                            : (_isSignUp
                                  ? 'Üye Ol ve Kişisel Ajandamı Başlat'
                                  : 'Hesabıma Giriş Yap'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (!_isSignUp) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    const Text(
                      'Kayıtlı Üye Hesapları (Simülatör Hızlı Seçim):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _emailCtrl.text =
                                    '@${SupabaseConfig.defaultHusbandUsername}';
                                _passwordCtrl.text =
                                    SupabaseConfig.defaultCouplePassword;
                              });
                              _submit();
                            },
                            child: const Text(
                              '@ilker Hesabı',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _emailCtrl.text =
                                    '@${SupabaseConfig.defaultWifeUsername}';
                                _passwordCtrl.text =
                                    SupabaseConfig.defaultCouplePassword;
                              });
                              _submit();
                            },
                            child: const Text(
                              '@neslihan Hesabı',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}
