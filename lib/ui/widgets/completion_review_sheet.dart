import 'package:flutter/material.dart';

import '../../domain/models/family_models.dart';

class CompletionReviewSheet extends StatefulWidget {
  final ScheduleBlock block;
  final void Function(String notes, List<ChecklistItem> updatedChecklist)
  onComplete;
  final void Function(String skipReason) onSkip;

  const CompletionReviewSheet({
    super.key,
    required this.block,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<CompletionReviewSheet> createState() => _CompletionReviewSheetState();
}

class _CompletionReviewSheetState extends State<CompletionReviewSheet> {
  late final TextEditingController _notesController;
  late final TextEditingController _skipReasonController;
  late List<ChecklistItem> _items;
  bool _isSkipMode = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.block.completionNotes,
    );
    _skipReasonController = TextEditingController(
      text: widget.block.skipReason,
    );
    _items = List<ChecklistItem>.from(widget.block.checklistItems);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _skipReasonController.dispose();
    super.dispose();
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
              children: [
                Expanded(
                  child: Text(
                    '${widget.block.title} (${widget.block.startTime} - ${widget.block.endTime})',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Ders/Görev Bitti (Neler Yaptım)'),
                  icon: Icon(Icons.task_alt),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Bugün Gitmedim / Atladım'),
                  icon: Icon(Icons.event_busy),
                ),
              ],
              selected: {_isSkipMode},
              onSelectionChanged: (val) =>
                  setState(() => _isSkipMode = val.first),
            ),
            const SizedBox(height: 16),
            if (!_isSkipMode) ...[
              if (_items.isNotEmpty) ...[
                Text(
                  'Sonraki İşten Önce Tik Atılacaklar:',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ..._items.map(
                  (item) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: item.done,
                    title: Text(
                      item.title,
                      style: TextStyle(
                        decoration: item.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    onChanged: (checked) {
                      setState(() {
                        final idx = _items.indexWhere((e) => e.id == item.id);
                        if (idx >= 0) {
                          _items[idx] = item.copyWith(done: checked ?? false);
                        }
                      });
                    },
                  ),
                ),
                const Divider(height: 20),
              ],
              Text(
                'Bu Saatte / Derste Neler Yaptın? (Özet & Notlar)',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Örn: Gitar dersinde bareli akorları çalıştık, yeni şarkının ilk bölümünü tamamladım...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onComplete(_notesController.text, _items);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.verified),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Tamamlandı Olarak İşaretle ve Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu dersi/planı atladığında haftalık istatistiklerde "Atlanan Planlar" listesinde takip edilir.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _skipReasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Atlama / Katılamama Nedeni',
                  hintText: 'Örn: Mesai uzadı / Yorgunluk / Yarına ertelendi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade800,
                  ),
                  onPressed: () {
                    widget.onSkip(_skipReasonController.text);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.event_busy),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Bugün Gidilmedi / Atlandı Olarak Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
