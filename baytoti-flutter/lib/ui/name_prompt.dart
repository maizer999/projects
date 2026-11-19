import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayName {
  static const _k = 'bayti_displayName';
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_k) ?? 'ضيف';
    return _cached!;
  }

  static Future<void> set(String name) async {
    _cached = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k, name);
  }

  static Future<bool> has() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_k);
  }
}

Future<String?> showNamePromptIfNeeded(BuildContext context) async {
  if (await DisplayName.has()) return null;
  if (!context.mounted) return null;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _NameDialog(),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ما اسمك؟'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سيظهر اسمك بجوار المشتريات التي تضيفها.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'اسمك'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await DisplayName.set('ضيف');
            if (context.mounted) Navigator.pop(context, 'ضيف');
          },
          child: const Text('تخطٍّ'),
        ),
        FilledButton(
          onPressed: () async {
            final v = _ctrl.text.trim().isEmpty ? 'ضيف' : _ctrl.text.trim();
            await DisplayName.set(v);
            if (context.mounted) Navigator.pop(context, v);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
