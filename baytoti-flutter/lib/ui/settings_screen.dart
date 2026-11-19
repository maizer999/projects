import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../main.dart';
import 'landing_screen.dart';
import 'name_prompt.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repo, required this.listId});
  final ListRepository repo;
  final String listId;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = 'ضيف';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await DisplayName.get();
    if (mounted) {
      setState(() {
        _name = n;
        _loaded = true;
      });
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسم العرض'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'الاسم'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) {
      await DisplayName.set(v);
      if (mounted) setState(() => _name = v);
    }
  }

  Future<void> _shareWhatsApp(ShoppingList list) async {
    final code = list.inviteCode;
    if (code == null) return;
    final url =
        'https://maizer999.github.io/projects/baytoti/invite.html?code=$code';
    final text =
        Uri.encodeComponent('انضم إلى قائمة "${list.name}" في بيتي بالرمز: $code\n$url');
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  Future<void> _archiveOld() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أرشفة المشتريات القديمة'),
        content: const Text(
            'سيتم نقل كل المشتريات الأقدم من 90 يوماً إلى الأرشيف. يمكنك استرجاعها لاحقاً.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('أرشفة')),
        ],
      ),
    );
    if (ok != true) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    await widget.repo.archiveOlderThan(widget.listId, cutoff);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الأرشفة')),
    );
  }

  Future<void> _leaveList(ShoppingList list) async {
    final me = await DisplayName.get();
    if (!mounted) return;
    if (list.isOwner(me)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('المالك لا يمكنه مغادرة القائمة. امسح القائمة بدلاً من ذلك.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مغادرة القائمة؟'),
        content: const Text('لن تتمكن من الوصول إلى هذه القائمة بعد الآن.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BaytiColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.repo.removeMember(widget.listId, me);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LandingScreen(repo: widget.repo),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: StreamBuilder<ShoppingList?>(
        stream: widget.repo.watchList(widget.listId),
        builder: (ctx, snap) {
          final list = snap.data;
          if (!_loaded || list == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              const _SectionHeader(label: 'الحساب'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('اسم العرض'),
                subtitle: Text(_name,
                    style: TextStyle(color: BaytiColors.muted)),
                trailing: const Icon(Icons.chevron_left),
                onTap: _editName,
              ),
              const _SectionHeader(label: 'القائمة'),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFF25D366)),
                title: const Text('مشاركة عبر واتساب'),
                onTap: () => _shareWhatsApp(list),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('أرشفة الأقدم من 90 يوماً'),
                subtitle: Text('ينقل مشتريات قديمة إلى الأرشيف',
                    style: TextStyle(color: BaytiColors.muted)),
                onTap: _archiveOld,
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app,
                    color: BaytiColors.danger),
                title: Text('مغادرة القائمة',
                    style: TextStyle(color: BaytiColors.danger)),
                onTap: () => _leaveList(list),
              ),
              const _SectionHeader(label: 'المظهر'),
              const _ThemePickerTile(),
              const _SectionHeader(label: 'عن التطبيق'),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('بيتي'),
                subtitle: Text('1.0.0', style: TextStyle(color: BaytiColors.muted)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: BaytiColors.muted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ThemePickerTile extends StatelessWidget {
  const _ThemePickerTile();

  @override
  Widget build(BuildContext context) {
    final app = BaytiApp.of(context);
    final currentId = app.presetId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final p in baytiPresets)
            _Swatch(
              preset: p,
              selected: p.id == currentId,
              onTap: () => app.setPreset(p.id),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });
  final BaytiPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [preset.primary, preset.accent],
              ),
              border: Border.all(
                color: selected ? BaytiColors.text : Colors.white,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: preset.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            preset.label,
            style: TextStyle(
              fontSize: 11,
              color: BaytiColors.muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
