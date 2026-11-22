import 'package:flutter/material.dart';

import '../data/arabic_text.dart';
import 'theme.dart';

class PricePromptResult {
  const PricePromptResult({required this.confirmed, this.price});
  final bool confirmed;
  final double? price;
}

Future<PricePromptResult?> showPricePrompt(
  BuildContext context, {
  required String itemName,
}) {
  return showDialog<PricePromptResult>(
    context: context,
    builder: (ctx) => _PricePromptDialog(itemName: itemName),
  );
}

class _PricePromptDialog extends StatefulWidget {
  const _PricePromptDialog({required this.itemName});
  final String itemName;

  @override
  State<_PricePromptDialog> createState() => _PricePromptDialogState();
}

class _PricePromptDialogState extends State<_PricePromptDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    final price = text.isEmpty ? null : parseFlexibleDouble(text);
    Navigator.pop(
      context,
      PricePromptResult(confirmed: true, price: price),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.bPrimary, context.bPrimaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: context.bPrimary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_checkout_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'شراء "${widget.itemName}"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.bPrimaryDark,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أدخل السعر إن أردت، أو اتركه فارغاً لنقل العنصر بدون سعر.',
            style: TextStyle(color: BaytiColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'السعر (د.أ)',
              prefixIcon: Icon(Icons.payments_outlined, size: 20),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const PricePromptResult(confirmed: false),
          ),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('نقل للمشتريات')),
      ],
    );
  }
}
