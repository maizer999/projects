import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/arabic_text.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'glass.dart';
import 'members_screen.dart';
import 'name_prompt.dart';
import 'price_prompt.dart';
import 'purchase_dialog.dart';
import 'quick_add_sheet.dart';
import 'settings_screen.dart';
import 'theme.dart';

enum _Tab { needs, purchases, history }

enum _Filter { week, all, archive }

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.repo, required this.listId});
  final ListRepository repo;
  final String listId;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  _Tab _tab = _Tab.needs;
  _Filter _filter = _Filter.week;

  List<Purchase> _purchases = [];
  List<WishItem> _wishlist = [];
  List<ProductStat> _topStats = const [];
  ShoppingList? _list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showNamePromptIfNeeded(context);
    });
    widget.repo.watchTopStats(widget.listId).listen((s) {
      if (mounted) setState(() => _topStats = s);
    });
  }

  bool _inCurrentWeek(DateTime d) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));
    return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Purchase> get _filteredPurchases {
    if (_filter == _Filter.all || _filter == _Filter.archive) return _purchases;
    return _purchases.where((p) => _inCurrentWeek(p.date)).toList();
  }

  double get _total => _filteredPurchases.fold(0.0, (s, p) => s + (p.price ?? 0));

  Future<bool> _confirmSameDayDup(String itemName) async {
    final key = normalizeAr(itemName);
    final today = DateTime.now();
    final dup = _purchases.any(
      (p) => normalizeAr(p.itemName) == key && _isSameDay(p.date, today),
    );
    if (!dup) return true;
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم شراء هذا العنصر اليوم'),
        content: Text('أضفت "$itemName" بالفعل اليوم. متابعة إضافته مرة أخرى؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _addNeed() async {
    final w = await showDialog<WishItem>(
      context: context,
      builder: (_) => const NeedDialog(),
    );
    if (w == null) return;
    final key = normalizeAr(w.itemName);
    final dup = _wishlist.any((e) => normalizeAr(e.itemName) == key);
    if (dup) {
      _snack('العنصر "${w.itemName}" موجود في النواقص مسبقاً');
      return;
    }
    await widget.repo.addWish(widget.listId, w);
  }

  Future<void> _addPurchase() async {
    final p = await showDialog<Purchase>(
      context: context,
      builder: (_) => PurchaseDialog(topStats: _topStats),
    );
    if (p == null) return;
    if (!await _confirmSameDayDup(p.itemName)) return;
    await widget.repo.addPurchase(widget.listId, p);
  }

  Future<void> _addFab() async {
    if (_tab == _Tab.needs) {
      await _addNeed();
    } else {
      await _addPurchase();
    }
  }

  Future<void> _quickAdd() async {
    final p = await showModalBottomSheet<Purchase>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddSheet(topStats: _topStats),
    );
    if (p == null) return;
    if (!await _confirmSameDayDup(p.itemName)) return;
    await widget.repo.addPurchase(widget.listId, p);
  }

  Future<void> _convertNeedViaCheckbox(WishItem w) async {
    final result = await showPricePrompt(context, itemName: w.itemName);
    if (result == null || !result.confirmed) return;
    final addedBy = await DisplayName.get();
    final p = Purchase(
      id: ListRepository.generateId(),
      itemName: w.itemName,
      price: result.price,
      category: PurchaseCategory.food,
      addedByName: addedBy,
      date: DateTime.now(),
    );
    await widget.repo.addPurchase(widget.listId, p);
    await widget.repo.deleteWish(widget.listId, w.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('تم نقل "${w.itemName}" إلى المشتريات'),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: BaytiColors.accent,
            onPressed: () async {
              await widget.repo.addWish(widget.listId, w);
              await widget.repo.deletePurchase(widget.listId, p.id);
            },
          ),
        ),
      );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editPurchase(Purchase p) async {
    final updated = await showDialog<Purchase>(
      context: context,
      builder: (_) => PurchaseDialog(initial: p),
    );
    if (updated != null) await widget.repo.updatePurchase(widget.listId, updated);
  }

  Future<void> _confirmDelete({required VoidCallback onConfirm}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنصر؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BaytiColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }

  Future<void> _share() async {
    final code = _list?.inviteCode;
    if (code == null) {
      _snack('رمز الدعوة غير متاح بعد');
      return;
    }
    final url =
        'https://maizer999.github.io/projects/baytoti/invite.html?code=$code';
    await SharePlus.instance.share(
      ShareParams(
        text: 'انضم إلى قائمة بيتي بالرمز: $code\n$url',
        subject: 'قائمة بيتي',
      ),
    );
  }

  void _openMembers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MembersScreen(repo: widget.repo, listId: widget.listId),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SettingsScreen(repo: widget.repo, listId: widget.listId),
      ),
    );
  }

  Future<void> _renameList() async {
    final list = _list;
    if (list == null) return;
    final me = await DisplayName.get();
    if (!mounted) return;
    if (!list.isOwner(me)) {
      _snack('المالك فقط يمكنه تغيير اسم القائمة');
      return;
    }
    final ctrl = TextEditingController(text: list.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسم القائمة'),
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
    if (newName != null && newName.isNotEmpty && newName != list.name) {
      await widget.repo.renameList(widget.listId, newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(),
      body: StreamBuilder<ShoppingList?>(
        stream: widget.repo.watchList(widget.listId),
        builder: (ctx, snap) {
          _list = snap.data;
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (_tab != _Tab.needs) _buildFilter(),
                if (_tab == _Tab.purchases) _buildHeroSummary(),
                Expanded(child: _buildContent()),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _tab == _Tab.history
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: GestureDetector(
                onLongPress: _tab == _Tab.purchases ? _quickAdd : null,
                child: FloatingActionButton.extended(
                  onPressed: _addFab,
                  icon: const Icon(Icons.add),
                  label: Text(_tab == _Tab.needs ? 'ناقص' : 'مشترى'),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 72,
      title: InkWell(
        onTap: _renameList,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _list?.name ?? 'بيتي',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 15, color: BaytiColors.muted),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'مشاركة',
          icon: const Icon(Icons.ios_share),
          onPressed: _share,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (v) {
            switch (v) {
              case 'members':
                _openMembers();
                break;
              case 'settings':
                _openSettings();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'members', child: Text('الأعضاء')),
            PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassBar(
        borderRadius: 24,
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => setState(() => _tab = _Tab.values[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checklist_rtl_outlined),
              selectedIcon: Icon(Icons.checklist_rtl),
              label: 'نواقص',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_basket_outlined),
              selectedIcon: Icon(Icons.shopping_basket),
              label: 'مشتريات',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'السجل',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter() {
    final chips = <Widget>[
      GlassPill(
        label: 'هذا الأسبوع',
        selected: _filter == _Filter.week,
        onTap: () => setState(() => _filter = _Filter.week),
      ),
      const SizedBox(width: 8),
      GlassPill(
        label: 'الكل',
        selected: _filter == _Filter.all,
        onTap: () => setState(() => _filter = _Filter.all),
      ),
      if (_tab == _Tab.history) ...[
        const SizedBox(width: 8),
        GlassPill(
          label: 'الأرشيف',
          icon: Icons.archive_outlined,
          selected: _filter == _Filter.archive,
          onTap: () => setState(() => _filter = _Filter.archive),
        ),
      ],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _buildHeroSummary() {
    final items = _filteredPurchases;
    return GlassHero(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.payments_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _filter == _Filter.week ? 'مصاريف هذا الأسبوع' : 'مصاريف الكل',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_total.toStringAsFixed(3)} د.أ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${items.length} عنصر',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_tab) {
      case _Tab.needs:
        return _buildNeedsTab();
      case _Tab.purchases:
      case _Tab.history:
        return _buildPurchasesTab();
    }
  }

  Widget _buildNeedsTab() {
    return StreamBuilder<List<WishItem>>(
      stream: widget.repo.watchWishlist(widget.listId),
      builder: (ctx, snap) {
        _wishlist = snap.data ?? const [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _TopAddButton(
                label: 'أضف شيئاً ناقصاً',
                icon: Icons.add_circle_outline,
                onTap: _addNeed,
              ),
            ),
            if (snap.connectionState == ConnectionState.waiting &&
                _wishlist.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_wishlist.isEmpty)
              const Expanded(
                child: _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'لا توجد نواقص',
                  subtitle: 'اضغط الزر أعلاه لإضافة ما يلزم البيت',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 140),
                  itemCount: _wishlist.length,
                  itemBuilder: (_, i) {
                    final w = _wishlist[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: GlassSurface(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                              right: 8, left: 4),
                          leading: Transform.scale(
                            scale: 1.15,
                            child: Checkbox(
                              value: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: BorderSide(
                                  color: BaytiColors.muted, width: 1.5),
                              onChanged: (_) => _convertNeedViaCheckbox(w),
                            ),
                          ),
                          title: Text(
                            w.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'أضافه ${w.addedByName}',
                            style: TextStyle(
                                color: BaytiColors.muted, fontSize: 12),
                          ),
                          trailing: IconButton(
                            tooltip: 'حذف',
                            icon: Icon(Icons.close,
                                color: BaytiColors.muted, size: 20),
                            onPressed: () => _confirmDelete(
                              onConfirm: () =>
                                  widget.repo.deleteWish(widget.listId, w.id),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPurchasesTab() {
    final viewingArchive =
        _tab == _Tab.history && _filter == _Filter.archive;
    return StreamBuilder<List<Purchase>>(
      stream: viewingArchive
          ? widget.repo.watchArchive(widget.listId)
          : widget.repo.watchPurchases(widget.listId),
      builder: (ctx, snap) {
        _purchases = snap.data ?? const [];
        if (snap.connectionState == ConnectionState.waiting &&
            _purchases.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = _tab == _Tab.purchases ? _filteredPurchases : _purchases;
        if (items.isEmpty) {
          return _EmptyState(
            icon: _tab == _Tab.purchases
                ? Icons.shopping_basket_outlined
                : (viewingArchive ? Icons.inventory : Icons.history),
            title: _tab == _Tab.purchases
                ? 'لا توجد مشتريات'
                : (viewingArchive ? 'الأرشيف فارغ' : 'السجل فارغ'),
            subtitle: _tab == _Tab.purchases ? 'اضغط + لإضافة مشترى' : '',
          );
        }
        final df = DateFormat('yyyy/MM/dd • HH:mm');
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 140),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final p = items[i];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GlassSurface(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _categoryColor(p.category)
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _categoryIcon(p.category),
                            color: _categoryColor(p.category),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${categoryLabelAr(p.category)} · ${p.addedByName} · ${df.format(p.date)}',
                                style: TextStyle(
                                  color: BaytiColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (p.price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: BaytiColors.primarySoft
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${p.price!.toStringAsFixed(3)} د.أ',
                              style: TextStyle(
                                color: BaytiColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (p.note != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: BaytiColors.accentSoft
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.sticky_note_2_outlined,
                                size: 16, color: Color(0xFFB45309)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                p.note!,
                                style: const TextStyle(
                                  color: Color(0xFF78350F),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _tab == _Tab.history
                          ? [
                              IconButton(
                                tooltip: p.archived ? 'استرجاع' : 'أرشفة',
                                icon: Icon(
                                  p.archived
                                      ? Icons.unarchive_outlined
                                      : Icons.archive_outlined,
                                  color: BaytiColors.muted,
                                  size: 20,
                                ),
                                onPressed: () => widget.repo.archivePurchase(
                                    widget.listId, p.id, !p.archived),
                              ),
                            ]
                          : [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    size: 20, color: BaytiColors.muted),
                                onPressed: () => _editPurchase(p),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: BaytiColors.danger, size: 20),
                                onPressed: () => _confirmDelete(
                                  onConfirm: () => widget.repo
                                      .deletePurchase(widget.listId, p.id),
                                ),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Color _categoryColor(PurchaseCategory c) {
  switch (c) {
    case PurchaseCategory.food:
      return BaytiColors.primary;
    case PurchaseCategory.cleaning:
      return const Color(0xFF6366F1);
    case PurchaseCategory.other:
      return BaytiColors.accent;
  }
}

IconData _categoryIcon(PurchaseCategory c) {
  switch (c) {
    case PurchaseCategory.food:
      return Icons.restaurant;
    case PurchaseCategory.cleaning:
      return Icons.cleaning_services;
    case PurchaseCategory.other:
      return Icons.inventory_2;
  }
}

class _TopAddButton extends StatelessWidget {
  const _TopAddButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      tint: BaytiColors.primary,
      opacity: 0.18,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BaytiColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: BaytiColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Icon(Icons.chevron_left,
              color: BaytiColors.primaryDark, size: 22),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    BaytiColors.primary.withValues(alpha: 0.18),
                    BaytiColors.accent.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Icon(icon, size: 42, color: BaytiColors.primaryDark),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                color: BaytiColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: BaytiColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
