import 'package:flutter/material.dart';

import '../data/arabic_text.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'name_prompt.dart';
import 'purchase_dialog.dart';
import 'theme.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key, this.topStats = const []});
  final List<ProductStat> topStats;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  PurchaseCategory _category = PurchaseCategory.food;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final price = parseFlexibleDouble(_priceCtrl.text);
    final addedBy = await DisplayName.get();
    final p = Purchase(
      id: ListRepository.generateId(),
      itemName: name,
      price: price,
      category: _category,
      addedByName: addedBy,
      date: DateTime.now(),
    );
    if (mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: BaytiColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('إضافة سريعة',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BaytiColors.primaryDark)),
            const SizedBox(height: 16),
            ProductAutocomplete(
              controller: _nameCtrl,
              onSelected: (p) {
                _nameCtrl.text = p.name;
                if (_priceCtrl.text.trim().isEmpty && p.price > 0) {
                  _priceCtrl.text = p.price.toStringAsFixed(3);
                }
                setState(() => _category = p.category);
              },
              label: 'المنتج',
              autofocus: true,
              topStats: widget.topStats,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'السعر (د.أ)'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
