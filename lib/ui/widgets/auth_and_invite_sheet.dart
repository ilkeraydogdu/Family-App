import 'package:flutter/material.dart';

import '../core/app_svg_icons.dart';
import '../view_models/planner_view_model.dart';

class AuthAndInviteSheet extends StatefulWidget {
  final PlannerViewModel viewModel;

  const AuthAndInviteSheet({super.key, required this.viewModel});

  @override
  State<AuthAndInviteSheet> createState() => _AuthAndInviteSheetState();
}

class _AuthAndInviteSheetState extends State<AuthAndInviteSheet> {
  int _modeIndex = 0; // 0: Eş / Arkadaş Davet & Bağlantılar, 1: Üyelik & Hesap
  bool _isSignUp = true;
  bool _isSubmitting = false;
  String? _statusBanner;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _joinInviteCodeController;

  late final TextEditingController _inviteeNameController;
  late final TextEditingController _inviteeEmailController;
  String _relationshipType = 'Eş / Hayat Arkadaşı';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _joinInviteCodeController = TextEditingController(
      text: widget.viewModel.familyProfile.inviteCode,
    );
    _inviteeNameController = TextEditingController();
    _inviteeEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _joinInviteCodeController.dispose();
    _inviteeNameController.dispose();
    _inviteeEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AppSvgIcon(
                    svgData: AppSvgs.usersCouple,
                    size: 20,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.viewModel.activeDisplayName} • Hesap & Ortak Bağlantılar',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kişisel planlarınız gizlidir; yalnızca ortak işler beraber görülür',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Segmented Switch
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      index: 0,
                      label: 'Ortak Eşleşme & Davet',
                      svg: AppSvgs.shareInvite,
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      index: 1,
                      label: 'Hesabım / Çıkış Yap',
                      svg: AppSvgs.userSingle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_statusBanner != null) ...[
              Container(
                width: double.infinity,
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
                      size: 18,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusBanner!,
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
              const SizedBox(height: 12),
            ],

            if (_modeIndex == 0)
              _buildPartnerInviteSection(context)
            else
              _buildAccountSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required String label,
    required String svg,
  }) {
    final selected = _modeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _modeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              svgData: svg,
              size: 15,
              color: selected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final vm = widget.viewModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppSvgIcon(
                  svgData: AppSvgs.userSingle,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.activeDisplayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      vm.activeUserEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await vm.signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                ),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Farklı Bir Üye Hesabı Oluştur veya Giriş Yap',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Yeni Üye Kaydı'),
              selected: _isSignUp,
              onSelected: (_) => setState(() => _isSignUp = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Mevcut Hesaba Giriş'),
              selected: !_isSignUp,
              onSelected: (_) => setState(() => _isSignUp = false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('Ad Soyad'),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('E-posta Adresi'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: _inputDecoration('Şifre'),
        ),
        if (_isSignUp) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _joinInviteCodeController,
            decoration: _inputDecoration('Ortak Plan Eşleşme Kodu (Opsiyonel)'),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submitAuth,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isSubmitting
                  ? 'İşleniyor...'
                  : (_isSignUp ? 'Yeni Üye Olarak Başla' : 'Hesaba Giriş Yap'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerInviteSection(BuildContext context) {
    final invitations = widget.viewModel.partnerInvitations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const AppSvgIcon(
                svgData: AppSvgs.shareInvite,
                size: 20,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ortak Plan Eşleşme Kodunuz',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.viewModel.familyProfile.inviteCode,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sadece Ortak İşler Paylaşılır',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Eş / Arkadaş Davet Et (Yalnızca Ortak Planları Görür)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inviteeNameController,
                decoration: _inputDecoration('Davet Edilen Üye Adı'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _relationshipType,
                isExpanded: true,
                decoration: _inputDecoration('Bağlantı Tipi'),
                items: const [
                  DropdownMenuItem(
                    value: 'Eş / Hayat Arkadaşı',
                    child: Text('Eş / Partner'),
                  ),
                  DropdownMenuItem(
                    value: 'Arkadaş / Çalışma Partneri',
                    child: Text('Arkadaş'),
                  ),
                  DropdownMenuItem(
                    value: 'Aile Üyesi',
                    child: Text('Aile Üyesi'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _relationshipType = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _inviteeEmailController,
          decoration: _inputDecoration('Davet E-postası (İsteğe Bağlı)'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _sendPartnerInvite,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Davet Oluştur & Bildirim Gönder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (invitations.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Ortak Plan Bağlantıları',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          ...invitations.take(3).map(
                (inv) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const AppSvgIcon(
                        svgData: AppSvgs.usersCouple,
                        size: 16,
                        color: Color(0xFF334155),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${inv.inviteeLabel} • ${inv.relationshipType}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        inv.inviteCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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

  Future<void> _submitAuth() async {
    setState(() {
      _isSubmitting = true;
      _statusBanner = null;
    });
    final err = await widget.viewModel.registerOrLoginUser(
      isSignUp: _isSignUp,
      displayName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      inviteCode: _joinInviteCodeController.text,
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _statusBanner = err == null
          ? 'Hesap aktif! Kişisel ajandanız ve ortak planlarınız yüklendi.'
          : 'Uyarı: $err';
    });
  }

  Future<void> _sendPartnerInvite() async {
    final label = _inviteeNameController.text.trim().isEmpty
        ? 'Neslihan'
        : _inviteeNameController.text.trim();
    await widget.viewModel.createPartnerInvite(
      inviteeLabel: label,
      relationshipType: _relationshipType,
      inviteeEmail: _inviteeEmailController.text,
    );
    if (!mounted) return;
    setState(() {
      _inviteeNameController.clear();
      _inviteeEmailController.clear();
      _statusBanner =
          '$label için ortak plan daveti oluşturuldu (kişisel planlarınız gizli kalır).';
    });
  }
}
