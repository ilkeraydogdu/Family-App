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
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.86;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
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
                        '${widget.viewModel.activeDisplayName} (${widget.viewModel.activeUsernameHandle})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'E-posta gizlidir • @kullanici_adi ile güvenli ortak plan ekosistemi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('close_auth_invite_sheet_btn'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mode Segmented Switch (Fixed above scroll area)
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            Flexible(
              child: ClipRect(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              ),
            ),
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
                      'Kullanıcı Adı: ${vm.activeUsernameHandle} • Kişisel Veri Gizli',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w600,
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
          decoration: _inputDecoration(
            'Kullanıcı Adı (Örn: @ilker veya @neslihan)',
          ),
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
        const SizedBox(height: 16),
        // Commercial Readiness: Family-App Pro Plan & App Store Guideline 5.1.1(v) Account Deletion
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSvgIcon(
                    svgData: AppSvgs.checkCircle,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Family-App Pro • Çift & Aile Paketi Aktif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Sınırsız @kullanici_adi ortak senkronizasyonu, canlı Diyanet namaz hizalama, açık kaynak hadis/dua ana ekran widget\'ları ve polifonik alarm motoru dahildir.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF166534),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KVKK / GDPR & App Store Veri Silme Hakkı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kişisel plan, ilaç ve su verilerinizi sunucudan kalıcı olarak temizler.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await vm.purgePersonalAccountAndSignOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Verilerimi Sil',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
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
          key: const ValueKey('invite_username_field'),
          controller: _inviteeEmailController,
          decoration: _inputDecoration(
            'Davet Edilecek @kullanici_adi (Örn: @neslihan, @ahmet_yilmaz)',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('send_partner_invite_btn'),
            onPressed: _sendPartnerInvite,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '@kullanici_adi İle Ortak Bağlantı Gönder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (invitations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Aktif & Bekleyen Ortak Bağlantılar (Duraklat / Kaldır)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          ...invitations.map(
            (inv) {
              final isAccepted = inv.status == 'accepted' && !inv.sharingPaused;
              final isPaused = inv.sharingPaused || inv.status == 'paused';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAccepted
                        ? const Color(0xFFBBF7D0)
                        : isPaused
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppSvgIcon(
                          svgData: AppSvgs.usersCouple,
                          size: 16,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inv.partnerDisplayFor(
                              widget.viewModel.activeUsername,
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isAccepted
                                ? const Color(0xFFDCFCE7)
                                : isPaused
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAccepted
                                ? 'Aktif Bağlantı'
                                : isPaused
                                ? 'Paylaşım Duraklatıldı'
                                : 'İstek Bekliyor',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isAccepted
                                  ? const Color(0xFF166534)
                                  : isPaused
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${inv.relationshipType} • Kod: ${inv.inviteCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (inv.status == 'pending')
                          OutlinedButton(
                            onPressed: () async {
                              await widget.viewModel
                                  .acceptOrReconnectPartnerInvitation(inv);
                              if (!mounted) return;
                              setState(() {
                                _statusBanner =
                                    '${inv.formattedTargetHandle} bağlantısı onaylandı ve ortak planlar senkronize edildi.';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              side: const BorderSide(color: Color(0xFF99F6E4)),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Bağlantıyı Onayla',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: () async {
                              await widget.viewModel
                                  .togglePausePartnerSharing(inv);
                              if (!mounted) return;
                              setState(() {
                                _statusBanner = isPaused
                                    ? '${inv.formattedTargetHandle} ile ortak plan paylaşımı yeniden açıldı.'
                                    : '${inv.formattedTargetHandle} ile ortak plan paylaşımı geçici olarak duraklatıldı.';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB45309),
                              side: const BorderSide(color: Color(0xFFFDE68A)),
                              visualDensity: VisualDensity.compact,
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
                          onPressed: () async {
                            await widget.viewModel
                                .removeOrUnlinkPartnerConnection(inv);
                            if (!mounted) return;
                            setState(() {
                              _statusBanner =
                                  '${inv.inviteeLabel} (${inv.formattedTargetHandle}) ortak bağlantısı kaldırıldı.';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB91C1C),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            inv.status == 'pending'
                                ? 'Daveti İptal Et / Sil'
                                : 'Bağlantıyı Kaldır / Sil',
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
            },
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
