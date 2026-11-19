import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'glass.dart';
import 'name_prompt.dart';
import 'theme.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.repo, required this.listId});
  final ListRepository repo;
  final String listId;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _me = '';

  @override
  void initState() {
    super.initState();
    DisplayName.get().then((n) {
      if (mounted) setState(() => _me = n);
    });
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رمز الدعوة')),
    );
  }

  Future<void> _share(String code, String name) async {
    final url =
        'https://maizer999.github.io/projects/baytoti/invite.html?code=$code';
    await SharePlus.instance.share(
      ShareParams(
        text: 'انضم إلى قائمة "$name" في بيتي بالرمز: $code\n$url',
        subject: 'قائمة بيتي',
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, String memberName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة العضو؟'),
        content: Text(
            'لن يتمكن "$memberName" من رؤية القائمة أو تعديلها بعد الآن.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BaytiColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.repo.removeMember(widget.listId, memberName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأعضاء')),
      body: StreamBuilder<ShoppingList?>(
        stream: widget.repo.watchList(widget.listId),
        builder: (ctx, snap) {
          final list = snap.data;
          if (list == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final isOwner = list.isOwner(_me);
          final code = list.inviteCode ?? '——';
          final editors = list.editors;
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
            children: [
              GlassHero(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رمز الدعوة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        _GlassIconButton(
                          icon: Icons.copy_rounded,
                          onTap: () => _copyCode(context, code),
                        ),
                        const SizedBox(width: 8),
                        _GlassIconButton(
                          icon: Icons.ios_share,
                          onTap: () => _share(code, list.name),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('الأعضاء (${1 + editors.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: BaytiColors.primary,
                    child: Icon(Icons.shield, color: Colors.white),
                  ),
                  title: Text(list.ownerName ?? '——'),
                  subtitle: Text('المالك',
                      style: TextStyle(color: BaytiColors.muted)),
                  trailing: list.ownerName == _me
                      ? const Chip(label: Text('أنت'))
                      : null,
                ),
              ),
              if (editors.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا يوجد محررون آخرون بعد. شارك رمز الدعوة لإضافة أفراد العائلة.',
                    style: TextStyle(color: BaytiColors.muted),
                  ),
                )
              else
                ...editors.map(
                  (member) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(member),
                      subtitle: Text('محرر',
                          style: TextStyle(color: BaytiColors.muted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (member == _me) const Chip(label: Text('أنت')),
                          if (isOwner && member != _me)
                            IconButton(
                              tooltip: 'إزالة',
                              icon: Icon(Icons.person_remove,
                                  color: BaytiColors.danger),
                              onPressed: () => _confirmRemove(context, member),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
