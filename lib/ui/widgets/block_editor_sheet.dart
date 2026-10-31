import 'package:flutter/material.dart';

import '../../domain/models/family_models.dart';

class BlockEditorSheet extends StatefulWidget {
  final int familyId;
  final String planDate;
  final String personalRoleKey;
  final bool initialShared;
  final ScheduleBlock? existingBlock;
  final ValueChanged<ScheduleBlock> onSave;
  final VoidCallback? onDelete;

  const BlockEditorSheet({
    super.key,
    required this.familyId,
    required this.planDate,
    this.personalRoleKey = 'husband',
    this.initialShared = false,
    this.existingBlock,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<BlockEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  final TextEditingController _newChecklistController = TextEditingController();

  String _ownerRole = 'shared';
  String _category = 'general';
  bool _isRecurringDaily = true;
  bool _isPrayerAnchored = false;
  String _prayerName = 'Fajr';
  int _prayerOffsetMinutes = 0;
  bool _voiceReminderEnabled = true;
  int _remindBeforeMinutes = 15;
  int _repeatCount = 3;
  int _repeatIntervalMinutes = 5;
  bool _phoneLockEnabled = false;
  late List<ChecklistItem> _checklistItems;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBlock;
    _titleController = TextEditingController(text: b?.title ?? '');
    _descController = TextEditingController(text: b?.description ?? '');
    _startTimeController = TextEditingController(text: b?.startTime ?? '09:00');
    _endTimeController = TextEditingController(text: b?.endTime ?? '11:00');
    _ownerRole = b?.ownerRole ??
        (widget.initialShared ? 'shared' : widget.personalRoleKey);
    _category = b?.category ?? 'lesson';
    _isRecurringDaily = b?.isRecurringDaily ?? true;
    _isPrayerAnchored = b?.isPrayerAnchored ?? false;
    _prayerName = b?.prayerName ?? 'Fajr';
    _prayerOffsetMinutes = b?.prayerOffsetMinutes ?? 0;
    _voiceReminderEnabled = b?.voiceReminderEnabled ?? true;
    _remindBeforeMinutes = b?.remindBeforeMinutes ?? 15;
    _repeatCount = b?.repeatCount ?? 3;
    _repeatIntervalMinutes = b?.repeatIntervalMinutes ?? 5;
    _phoneLockEnabled = b?.phoneLockEnabled ?? false;
    _checklistItems = List<ChecklistItem>.from(b?.checklistItems ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _newChecklistController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '9') ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hh:$mm';
      });
    }
  }

  void _addChecklistItem() {
    final text = _newChecklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklistItems.add(
        ChecklistItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          done: false,
        ),
      );
      _newChecklistController.clear();
    });
  }

  Widget _templateChip({
    required String label,
    required String title,
    required String desc,
    required String start,
    required String end,
    bool prayerAnchored = false,
    String prayerName = 'Fajr',
    int prayerOffset = 0,
    bool phoneLock = false,
    bool shared = false,
  }) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      onPressed: () {
        setState(() {
          _titleController.text = title;
          _descController.text = desc;
          _startTimeController.text = start;
          _endTimeController.text = end;
          _isPrayerAnchored = prayerAnchored;
          _prayerName = prayerName;
          _prayerOffsetMinutes = prayerOffset;
          _phoneLockEnabled = phoneLock;
          _ownerRole = shared ? 'shared' : widget.personalRoleKey;
        });
      },
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen plan başlığını yazın kanka.')),
      );
      return;
    }

    final block = ScheduleBlock(
      id: widget.existingBlock?.id,
      familyId: widget.familyId,
      ownerRole: _ownerRole,
      title: title,
      description: _descController.text.trim(),
      category: _category,
      planDate: widget.planDate,
      isRecurringDaily: _isRecurringDaily,
      recurrenceDays: const [1, 2, 3, 4, 5, 6, 7],
      startTime: _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim(),
      isPrayerAnchored: _isPrayerAnchored,
      prayerName: _isPrayerAnchored ? _prayerName : null,
      prayerOffsetMinutes: _isPrayerAnchored ? _prayerOffsetMinutes : 0,
      voiceReminderEnabled: _voiceReminderEnabled,
      remindBeforeMinutes: _remindBeforeMinutes,
      repeatCount: _repeatCount,
      repeatIntervalMinutes: _repeatIntervalMinutes,
      phoneLockEnabled: _phoneLockEnabled,
      allowCallsOnly: true,
      status: widget.existingBlock?.status ?? 'planned',
      checkedInAt: widget.existingBlock?.checkedInAt,
      completedAt: widget.existingBlock?.completedAt,
      skipReason: widget.existingBlock?.skipReason ?? '',
      completionNotes: widget.existingBlock?.completionNotes ?? '',
      checklistItems: _checklistItems,
    );

    widget.onSave(block);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingBlock == null
                      ? 'Yeni Saatlik Plan Ekle'
                      : 'Planı Düzenle',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  key: const ValueKey('close_block_editor_btn'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (widget.existingBlock == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Hızlı Rutin Şablonları (Tek Dokunuşla Doldur)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _templateChip(
                      label: 'Sabah Namazı & Zikir',
                      title: 'Sabah Namazı & Tesbihat',
                      desc: 'Canlı Diyanet imsak/sabah vaktine göre hizalı ibadet',
                      start: '06:00',
                      end: '06:35',
                      prayerAnchored: true,
                      prayerName: 'Fajr',
                      shared: true,
                    ),
                    const SizedBox(width: 6),
                    _templateChip(
                      label: 'Servis & İşe Gidiş',
                      title: 'Servis Yürüyüşü & İşe Gidiş',
                      desc: 'Sabah namazı sonrası servise yürüyüş ve iş başlangıcı',
                      start: '06:45',
                      end: '08:00',
                      prayerAnchored: true,
                      prayerName: 'Fajr',
                      prayerOffset: 45,
                      shared: false,
                    ),
                    const SizedBox(width: 6),
                    _templateChip(
                      label: 'Gitar / Özel Ders',
                      title: 'Gitar Dersi & Pratik',
                      desc: 'Ders süresi boyunca odak kalkanı ve alt görev kontrolü',
                      start: '09:00',
                      end: '11:00',
                      phoneLock: true,
                      shared: false,
                    ),
                    const SizedBox(width: 6),
                    _templateChip(
                      label: 'Akşam Aile & Yemek',
                      title: 'Akşam Yemeği & Eş Sohbeti',
                      desc: 'Telefonlar sessizde birlikte kaliteli aile vakti',
                      start: '19:30',
                      end: '21:00',
                      phoneLock: true,
                      shared: true,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('block_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Plan / Ders / Rutin Başlığı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_note),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('block_desc_field'),
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Açıklama / Detay',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Plan Gizliliği & Görünürlük',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Kişisel Planım (Sadece Ben)'),
                  icon: Icon(Icons.lock_outline),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Ortak Plan (Beraber Görülür)'),
                  icon: Icon(Icons.group_outlined),
                ),
              ],
              selected: {_ownerRole == 'shared'},
              onSelectionChanged: (val) => setState(
                () => _ownerRole =
                    val.first ? 'shared' : widget.personalRoleKey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tekrarlama & Tarih Seçeneği',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              segments: [
                const ButtonSegment(
                  value: true,
                  label: Text('Her Gün Tekrarla (Rutin)'),
                  icon: Icon(Icons.repeat_rounded),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Sadece ${widget.planDate}'),
                  icon: const Icon(Icons.today_rounded),
                ),
              ],
              selected: {_isRecurringDaily},
              onSelectionChanged: (val) =>
                  setState(() => _isRecurringDaily = val.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(_startTimeController),
                    child: IgnorePointer(
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Başlangıç Saati',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(_endTimeController),
                    child: IgnorePointer(
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Bitiş Saati',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timelapse),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'lesson',
                  child: Text('Eğitim / Gitar & Ders'),
                ),
                DropdownMenuItem(
                  value: 'prayer',
                  child: Text('Namaz & İbadet'),
                ),
                DropdownMenuItem(
                  value: 'commute',
                  child: Text('Servis & Yürüyüş'),
                ),
                DropdownMenuItem(value: 'work', child: Text('İş & Mesai')),
                DropdownMenuItem(
                  value: 'sleep',
                  child: Text('Uyanış & Uyku Rutini'),
                ),
                DropdownMenuItem(
                  value: 'focus',
                  child: Text('Telefonsuz Aile Odak Saati'),
                ),
                DropdownMenuItem(
                  value: 'personal',
                  child: Text('Kişisel Rutin & Hazırlık'),
                ),
                DropdownMenuItem(value: 'general', child: Text('Genel Plan')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Canlı Namaz Vaktine Göre Otomatik Hizala',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Sabah/Öğle/Akşam namaz saatleri değiştikçe saati canlı günceller',
              ),
              value: _isPrayerAnchored,
              onChanged: (val) => setState(() => _isPrayerAnchored = val),
            ),
            if (_isPrayerAnchored) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _prayerName,
                      decoration: const InputDecoration(
                        labelText: 'Baz Alınacak Vakit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Fajr',
                          child: Text('Sabah / İmsak'),
                        ),
                        DropdownMenuItem(value: 'Dhuhr', child: Text('Öğle')),
                        DropdownMenuItem(value: 'Asr', child: Text('İkindi')),
                        DropdownMenuItem(
                          value: 'Maghrib',
                          child: Text('Akşam'),
                        ),
                        DropdownMenuItem(value: 'Isha', child: Text('Yatsı')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _prayerName = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _prayerOffsetMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Vakte Göre Fark',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: -45, child: Text('45 dk önce')),
                        DropdownMenuItem(value: -30, child: Text('30 dk önce')),
                        DropdownMenuItem(value: -15, child: Text('15 dk önce')),
                        DropdownMenuItem(value: 0, child: Text('Tam vaktinde')),
                        DropdownMenuItem(value: 30, child: Text('30 dk sonra')),
                        DropdownMenuItem(
                          value: 45,
                          child: Text('45 dk sonra (Servis)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _prayerOffsetMinutes = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Sesli Alarm & Tekrarlı Hatırlatıcı',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                '"Başladım" diyene kadar seçili alarm zil sesiyle hatırlatır',
              ),
              value: _voiceReminderEnabled,
              onChanged: (val) => setState(() => _voiceReminderEnabled = val),
            ),
            if (_voiceReminderEnabled) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _remindBeforeMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Kaç dk kala?',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 dk')),
                        DropdownMenuItem(value: 10, child: Text('10 dk')),
                        DropdownMenuItem(value: 15, child: Text('15 dk')),
                        DropdownMenuItem(value: 20, child: Text('20 dk')),
                        DropdownMenuItem(value: 30, child: Text('30 dk')),
                        DropdownMenuItem(value: 45, child: Text('45 dk')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _remindBeforeMinutes = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _repeatCount,
                      decoration: const InputDecoration(
                        labelText: 'Tekrar',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 kez')),
                        DropdownMenuItem(value: 2, child: Text('2 kez')),
                        DropdownMenuItem(value: 3, child: Text('3 kez')),
                        DropdownMenuItem(value: 5, child: Text('5 kez')),
                        DropdownMenuItem(value: 10, child: Text('10 kez')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _repeatCount = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _repeatIntervalMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Aralık',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('2 dk')),
                        DropdownMenuItem(value: 3, child: Text('3 dk')),
                        DropdownMenuItem(value: 5, child: Text('5 dk')),
                        DropdownMenuItem(value: 10, child: Text('10 dk')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _repeatIntervalMinutes = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Bu Saatte Telefonu Kullanım Dışı Bırak (Sadece Aramalar)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Etkinlik süresince odak kalkanı açılır, sadece aramalara cevap verilebilir',
              ),
              value: _phoneLockEnabled,
              onChanged: (val) => setState(() => _phoneLockEnabled = val),
            ),
            const Divider(height: 20),
            Text(
              'Alt Görevler & Ders Sonu Tik Listesi',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newChecklistController,
                    decoration: const InputDecoration(
                      hintText: 'Örn: Akor geçişleri 15 dk çalışıldı',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addChecklistItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _addChecklistItem,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._checklistItems.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_box_outline_blank, size: 20),
                title: Text(item.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      _checklistItems.removeWhere((e) => e.id == item.id);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Planı Kaydet ve Senkronize Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (widget.existingBlock != null && widget.onDelete != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Bu Saatlik Planı Sil',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
