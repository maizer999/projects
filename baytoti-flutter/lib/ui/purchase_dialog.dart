import 'package:flutter/material.dart';

import '../data/arabic_text.dart';
import '../data/models.dart';
import '../data/product_catalog.dart';
import '../data/repository.dart';
import 'name_prompt.dart';

class PurchaseDialog extends StatefulWidget {
  const PurchaseDialog({super.key, this.initial, this.topStats = const []});
  final Purchase? initial;
  final List<ProductStat> topStats;

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;
  late PurchaseCategory _category;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.itemName ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initial?.price?.toStringAsFixed(3) ?? '',
    );
    _noteCtrl = TextEditingController(text: widget.initial?.note ?? '');
    _category = widget.initial?.category ?? PurchaseCategory.food;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onProductPicked(Product p) {
    _nameCtrl.text = p.name;
    if (_priceCtrl.text.trim().isEmpty) {
      _priceCtrl.text = p.price.toStringAsFixed(3);
    }
    setState(() => _category = p.category);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final priceText = _priceCtrl.text.trim();
    final price = priceText.isEmpty ? null : parseFlexibleDouble(priceText);
    final note = _noteCtrl.text.trim();
    final addedBy = await DisplayName.get();
    final result = Purchase(
      id: widget.initial?.id ?? ListRepository.generateId(),
      itemName: name,
      price: price,
      category: _category,
      addedByName: widget.initial?.addedByName ?? addedBy,
      date: widget.initial?.date ?? DateTime.now(),
      note: note.isEmpty ? null : note,
      archived: widget.initial?.archived ?? false,
    );
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'تعديل مشترى' : 'إضافة مشترى'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProductAutocomplete(
              controller: _nameCtrl,
              onSelected: _onProductPicked,
              label: 'اسم المنتج',
              topStats: widget.topStats,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر بالدينار (د.أ)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PurchaseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'الفئة'),
              items: PurchaseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(categoryLabelAr(c)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}

class NeedDialog extends StatefulWidget {
  const NeedDialog({super.key});

  @override
  State<NeedDialog> createState() => _NeedDialogState();
}

class _NeedDialogState extends State<NeedDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final addedBy = await DisplayName.get();
    final w = WishItem(
      id: ListRepository.generateId(),
      itemName: name,
      addedByName: addedBy,
      createdAt: DateTime.now(),
    );
    if (mounted) Navigator.pop(context, w);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة ناقص'),
      content: SizedBox(
        width: 320,
        child: ProductAutocomplete(
          controller: _ctrl,
          onSelected: (p) => _ctrl.text = p.name,
          label: 'اسم العنصر',
          autofocus: true,
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}

class ProductAutocomplete extends StatelessWidget {
  const ProductAutocomplete({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.label,
    this.autofocus = false,
    this.onSubmitted,
    this.topStats = const [],
  });

  final TextEditingController controller;
  final ValueChanged<Product> onSelected;
  final String label;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final List<ProductStat> topStats;

  List<Product> _buildOptions(String rawQuery) {
    final query = normalizeAr(rawQuery);
    if (query.isEmpty) return const [];
    final matches = searchCatalogGrouped(rawQuery);
    final statMatches = topStats
        .where((s) => normalizeAr(s.name).contains(query))
        .where((s) => findProductByName(s.name) == null)
        .map((s) => Product(
              name: s.name,
              price: 0.0,
              category: PurchaseCategory.other,
            ))
        .toList();
    return [...statMatches, ...matches];
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Product>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (value) => _buildOptions(value.text),
      displayStringForOption: (p) => p.name,
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, focus, _) => TextField(
        controller: ctrl,
        focusNode: focus,
        autofocus: autofocus,
        decoration: InputDecoration(labelText: label),
        onSubmitted: onSubmitted,
      ),
      optionsViewBuilder: (ctx, onSelect, options) {
        final list = options.toList();
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 360),
              child: _GroupedOptions(
                options: list,
                onSelect: onSelect,
                topStatNames:
                    topStats.map((s) => normalizeAr(s.name)).toSet(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupedOptions extends StatelessWidget {
  const _GroupedOptions({
    required this.options,
    required this.onSelect,
    required this.topStatNames,
  });

  final List<Product> options;
  final void Function(Product) onSelect;
  final Set<String> topStatNames;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Product>>{};
    for (final p in options) {
      final key = topStatNames.contains(normalizeAr(p.name))
          ? 'الأكثر طلباً'
          : categoryLabelAr(p.category);
      (groups[key] ??= []).add(p);
    }
    final ordered = ['الأكثر طلباً', 'طعام', 'منظفات', 'أخرى']
        .where(groups.containsKey)
        .toList();
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        for (final g in ordered) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            color: Colors.black.withValues(alpha: 0.03),
            child: Text(
              g,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          for (final p in groups[g]!)
            ListTile(
              dense: true,
              title: Text(p.name),
              trailing: p.price > 0
                  ? Text(
                      '${p.price.toStringAsFixed(3)} د.أ',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              onTap: () => onSelect(p),
            ),
        ],
      ],
    );
  }
}
