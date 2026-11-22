import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../data/repository.dart';
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
      backgroundColor: BaytiColors.bg,
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
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
            children: [
              _inviteCard(context, code, list.name),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'الأعضاء',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.bPrimarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${1 + editors.length}',
                        style: TextStyle(
                          color: context.bPrimaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _memberTile(
                context,
                name: list.ownerName ?? '——',
                role: 'المالك',
                isOwnerRow: true,
                isMe: list.ownerName == _me,
              ),
              if (editors.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(
                    'لا يوجد محررون آخرون بعد. شارك رمز الدعوة لإضافة أفراد العائلة.',
                    style: TextStyle(
                      color: BaytiColors.muted,
                      height: 1.7,
                    ),
                  ),
                )
              else
                ...editors.map(
                  (member) => _memberTile(
                    context,
                    name: member,
                    role: 'محرر',
                    isOwnerRow: false,
                    isMe: member == _me,
                    canRemove: isOwner && member != _me,
                    onRemove: () => _confirmRemove(context, member),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _inviteCard(BuildContext context, String code, String name) {
    final primary = context.bPrimary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primary.withValues(alpha: 0.10),
            BaytiColors.summaryBg,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BaytiColors.summaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded,
                  size: 18, color: context.bPrimaryDark),
              const SizedBox(width: 6),
              Text(
                'رمز الدعوة',
                style: TextStyle(
                  color: context.bPrimaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: context.bPrimaryDark,
                    letterSpacing: 8,
                    height: 1,
                  ),
                ),
              ),
              _InviteIconButton(
                icon: Icons.copy_rounded,
                onTap: () => _copyCode(context, code),
              ),
              const SizedBox(width: 8),
              _InviteIconButton(
                icon: Icons.ios_share_rounded,
                onTap: () => _share(code, name),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'شارك هذا الرمز مع أفراد العائلة ليتمكنوا من الانضمام للقائمة.',
            style: TextStyle(
              color: BaytiColors.muted,
              fontSize: 12.5,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(
    BuildContext context, {
    required String name,
    required String role,
    required bool isOwnerRow,
    required bool isMe,
    bool canRemove = false,
    VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BaytiColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaytiColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOwnerRow
                    ? [context.bPrimary, context.bPrimaryDark]
                    : [BaytiColors.accent, BaytiColors.mutedSoft],
              ),
            ),
            child: Icon(
              isOwnerRow ? Icons.shield_rounded : Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: BaytiColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    color: BaytiColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.bPrimarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'أنت',
                style: TextStyle(
                  color: context.bPrimaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (canRemove)
            IconButton(
              tooltip: 'إزالة',
              icon: const Icon(Icons.person_remove_rounded,
                  color: BaytiColors.danger),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _InviteIconButton extends StatelessWidget {
  const _InviteIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: BaytiColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BaytiColors.line),
          boxShadow: BaytiShadows.sm,
        ),
        child: Icon(icon, color: context.bPrimaryDark, size: 18),
      ),
    );
  }
}