import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/arabic_text.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'members_screen.dart';
import 'name_prompt.dart';
import 'purchase_dialog.dart';
import 'quick_add_sheet.dart';
import 'settings_screen.dart';
import 'theme.dart';

enum _Tab { needs, purchases, history }

enum _Filter { week, all }

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
    if (_filter == _Filter.all) return _purchases;
    return _purchases.where((p) => _inCurrentWeek(p.date)).toList();
  }

  double get _total =>
      _filteredPurchases.fold(0.0, (s, p) => s + (p.price ?? 0));

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

  Future<void> _convertNeedViaCheckbox(WishItem w, {double? price}) async {
    final addedBy = await DisplayName.get();
    final p = Purchase(
      id: ListRepository.generateId(),
      itemName: w.itemName,
      price: price,
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
            textColor: Colors.white,
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
    if (updated != null) {
      await widget.repo.updatePurchase(widget.listId, updated);
    }
  }

  Future<void> _confirmDelete({required VoidCallback onConfirm}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنصر؟'),
        actionsAlignment: MainAxisAlignment.center,
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
      backgroundColor: BaytiColors.bg,
      floatingActionButton: _tab == _Tab.history ? null : _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: StreamBuilder<ShoppingList?>(
              stream: widget.repo.watchList(widget.listId),
              builder: (ctx, snap) {
                _list = snap.data;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: BaytiColors.card,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: BaytiColors.line),
                      boxShadow: BaytiShadows.md,
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildTabs(),
                        const SizedBox(height: 14),
                        Expanded(child: _buildContent()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    final primary = context.bPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: GestureDetector(
        onLongPress: _tab == _Tab.purchases ? _quickAdd : null,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _addFab,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final memberCount = _list == null
        ? 0
        : (_list!.editors.length + (_list!.ownerName != null ? 1 : 0));
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _renameList,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _list?.name ?? 'بيت العائلة',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.bPrimaryDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded,
                          size: 14, color: BaytiColors.placeholder),
                    ],
                  ),
                  if (memberCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$memberCount ${memberCount == 1 ? 'عضو' : 'أعضاء'}',
                      style: const TextStyle(
                        color: BaytiColors.mutedSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _pillIconText(
          icon: Icons.ios_share_rounded,
          label: 'مشاركة',
          onTap: _share,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: BaytiColors.card,
        border: Border(top: BorderSide(color: BaytiColors.line)),
        boxShadow: BaytiShadows.sm,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navButton(
                icon: Icons.settings_outlined,
                label: 'الإعدادات',
                onTap: _openSettings,
              ),
              _navButton(
                icon: Icons.people_outline_rounded,
                label: 'الأعضاء',
                onTap: _openMembers,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: context.bPrimaryDark),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: context.bPrimaryDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillIconText({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: BaytiColors.chipBg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: BaytiColors.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                    color: BaytiColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = const [
      ('النواقص', _Tab.needs),
      ('المشتريات', _Tab.purchases),
      ('السجل', _Tab.history),
    ];
    final selectedIndex = tabs.indexWhere((t) => t.$2 == _tab);
    return LayoutBuilder(
      builder: (ctx, c) {
        final innerWidth = c.maxWidth - 8;
        final itemWidth = innerWidth / tabs.length;
        return Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: BaytiColors.itemCardHover,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                right: selectedIndex * itemWidth,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: BaytiColors.card,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: BaytiShadows.sm,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (label, tab) in tabs)
                    Expanded(child: _tabButton(label, tab)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabButton(String label, _Tab tab) {
    final active = _tab == tab;
    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: () => setState(() => _tab = tab),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            color: active ? context.bPrimaryDark : BaytiColors.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_tab) {
      case _Tab.needs:
        return _buildNeedsTab();
      case _Tab.purchases:
        return _buildPurchasesTab();
      case _Tab.history:
        return _buildHistoryTab();
    }
  }

  // ===== NEEDS TAB =====

  Widget _buildNeedsTab() {
    return StreamBuilder<List<WishItem>>(
      stream: widget.repo.watchWishlist(widget.listId),
      builder: (ctx, snap) {
        _wishlist = snap.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _primaryPillButton(
                  icon: Icons.add_rounded,
                  label: 'إضافة عنصر',
                  onTap: _addNeed,
                ),
                const Spacer(),
                if (_wishlist.isNotEmpty)
                  Text(
                    '${_wishlist.length} عنصر',
                    style: const TextStyle(
                      color: BaytiColors.mutedSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (snap.connectionState == ConnectionState.waiting &&
                _wishlist.isEmpty)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_wishlist.isEmpty)
              const Expanded(
                child: _EmptyState(
                  emoji: '📝',
                  message: 'لا توجد نواقص حالياً',
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => widget.repo.refresh(widget.listId),
                  color: context.bPrimary,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _wishlist.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _needRow(_wishlist[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _needRow(WishItem w) {
    return _NeedRow(
      key: ValueKey(w.id),
      wish: w,
      primary: context.bPrimary,
      onCheck: (price) => _convertNeedViaCheckbox(w, price: price),
      onDelete: () => _confirmDelete(
        onConfirm: () => widget.repo.deleteWish(widget.listId, w.id),
      ),
      cardBuilder: ({required Widget child}) => _itemCard(child: child),
      deleteButton: ({required VoidCallback onTap}) => _iconBtn(
        icon: Icons.delete_outline_rounded,
        danger: true,
        onTap: onTap,
      ),
    );
  }

  // ===== PURCHASES TAB =====

  Widget _buildPurchasesTab() {
    return StreamBuilder<List<Purchase>>(
      stream: widget.repo.watchPurchases(widget.listId),
      builder: (ctx, snap) {
        _purchases = snap.data ?? const [];
        if (snap.connectionState == ConnectionState.waiting &&
            _purchases.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = _filteredPurchases
          ..sort((a, b) => b.date.compareTo(a.date));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _filterChips(),
            const SizedBox(height: 12),
            _summaryCard(count: items.length, total: _total),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Expanded(
                child: _EmptyState(
                  emoji: '🛒',
                  message: 'لا توجد مشتريات هذا الأسبوع — أضف أول مشترى',
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => widget.repo.refresh(widget.listId),
                  color: context.bPrimary,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _purchaseRow(items[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filterChips() {
    return Row(
      children: [
        _chip('هذا الأسبوع', selected: _filter == _Filter.week,
            onTap: () => setState(() => _filter = _Filter.week)),
        const SizedBox(width: 8),
        _chip('الكل',
            selected: _filter == _Filter.all,
            onTap: () => setState(() => _filter = _Filter.all)),
      ],
    );
  }

  Widget _chip(String label,
      {required bool selected, required VoidCallback onTap}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: context.bPrimary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: selected ? context.bPrimary : BaytiColors.chipBg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF5E5249),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({required int count, required double total}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            BaytiColors.summaryBg,
            Color.lerp(BaytiColors.summaryBg, context.bPrimarySoft, 0.35) ??
                BaytiColors.summaryBg,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BaytiColors.summaryBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryCell('عدد العناصر', '$count')),
          Container(
            width: 1,
            height: 40,
            color: BaytiColors.summaryBorder,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _summaryCell(
              'المجموع',
              '${total.toStringAsFixed(2)} د.أ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: BaytiColors.mutedSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.bPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _purchaseRow(Purchase p) {
    final df = DateFormat('d MMM', 'ar');
    return _itemCard(
      onTap: () => _editPurchase(p),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _categoryBadge(p.category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: BaytiColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  children: [
                    if (p.price != null)
                      Text(
                        '${p.price!.toStringAsFixed(2)} د.أ',
                        style: TextStyle(
                          color: context.bPrimaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    Text(p.addedByName, style: _metaStyle),
                    Text(df.format(p.date), style: _metaStyle),
                  ],
                ),
              ],
            ),
          ),
          _iconBtn(
            icon: Icons.delete_outline_rounded,
            danger: true,
            onTap: () => _confirmDelete(
              onConfirm: () =>
                  widget.repo.deletePurchase(widget.listId, p.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(PurchaseCategory c) {
    final (icon, color) = switch (c) {
      PurchaseCategory.food => (Icons.restaurant_rounded, const Color(0xFFC08457)),
      PurchaseCategory.cleaning =>
        (Icons.cleaning_services_rounded, const Color(0xFF6B8CAE)),
      PurchaseCategory.other =>
        (Icons.inventory_2_outlined, const Color(0xFF9A8E82)),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  // ===== HISTORY TAB =====

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Purchase>>(
      stream: widget.repo.watchPurchases(widget.listId),
      builder: (ctx, snap) {
        _purchases = snap.data ?? const [];
        if (snap.connectionState == ConnectionState.waiting &&
            _purchases.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_purchases.isEmpty) {
          return const _EmptyState(
            emoji: '📅',
            message: 'لا توجد مشتريات مسجّلة بعد',
          );
        }

        final groups = <int, _WeekGroup>{};
        for (final p in _purchases) {
          final start = _sundayStart(p.date);
          final key = start.millisecondsSinceEpoch;
          final g = groups[key] ??
              _WeekGroup(start: start, count: 0, total: 0);
          g.count += 1;
          if (p.price != null) g.total += p.price!;
          groups[key] = g;
        }
        final weeks = groups.values.toList()
          ..sort((a, b) => b.start.compareTo(a.start));
        final todayKey = _sundayStart(DateTime.now()).millisecondsSinceEpoch;

        return RefreshIndicator(
          onRefresh: () => widget.repo.refresh(widget.listId),
          color: context.bPrimary,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: weeks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final w = weeks[i];
              return _historyRow(w,
                  isCurrent: w.start.millisecondsSinceEpoch == todayKey);
            },
          ),
        );
      },
    );
  }

  Widget _historyRow(_WeekGroup w, {required bool isCurrent}) {
    final df = DateFormat('d MMM', 'ar');
    final dfYear = DateFormat('d MMM y', 'ar');
    final end = w.start.add(const Duration(days: 6));
    final startStr = df.format(w.start);
    final endStr = dfYear.format(end);
    final label = isCurrent ? 'هذا الأسبوع' : 'أسبوع $startStr';
    return _itemCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.bPrimarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded,
                size: 18, color: context.bPrimaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: BaytiColors.text,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.bPrimary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'جاري',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$startStr — $endStr',
                  style: const TextStyle(
                    color: BaytiColors.mutedSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${w.total.toStringAsFixed(2)} د.أ',
                style: TextStyle(
                  color: context.bPrimaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${w.count} عنصر',
                style: const TextStyle(
                  color: BaytiColors.mutedSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _sundayStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final offset = day.weekday % 7;
    return day.subtract(Duration(days: offset));
  }

  // ===== Reusable pieces =====

  TextStyle get _metaStyle => const TextStyle(
        fontSize: 12.5,
        color: BaytiColors.mutedSoft,
        fontWeight: FontWeight.w500,
      );

  Widget _itemCard({required Widget child, VoidCallback? onTap}) {
    return Material(
      color: BaytiColors.itemCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BaytiColors.line, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: BaytiColors.chipHover.withValues(alpha: 0.2),
        highlightColor: BaytiColors.itemCardHover,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        splashColor: danger ? BaytiColors.dangerSoft : BaytiColors.chipHover,
        highlightColor:
            danger ? BaytiColors.dangerSoft : BaytiColors.chipHover,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: danger ? BaytiColors.danger : BaytiColors.mutedSoft,
          ),
        ),
      ),
    );
  }

  Widget _primaryPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primary = context.bPrimary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: primary,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedRow extends StatefulWidget {
  const _NeedRow({
    super.key,
    required this.wish,
    required this.primary,
    required this.onCheck,
    required this.onDelete,
    required this.cardBuilder,
    required this.deleteButton,
  });

  final WishItem wish;
  final Color primary;
  final void Function(double? price) onCheck;
  final VoidCallback onDelete;
  final Widget Function({required Widget child}) cardBuilder;
  final Widget Function({required VoidCallback onTap}) deleteButton;

  @override
  State<_NeedRow> createState() => _NeedRowState();
}

class _NeedRowState extends State<_NeedRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleCheck() {
    final text = _ctrl.text.trim();
    final price = text.isEmpty ? null : parseFlexibleDouble(text);
    widget.onCheck(price);
  }

  @override
  Widget build(BuildContext context) {
    return widget.cardBuilder(
      child: Row(
        children: [
          Transform.scale(
            scale: 1.15,
            child: Checkbox(
              value: false,
              activeColor: widget.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: const BorderSide(color: BaytiColors.muted, width: 1.5),
              onChanged: (_) => _handleCheck(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.wish.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: BaytiColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.wish.addedByName,
                  style: const TextStyle(
                    color: BaytiColors.mutedSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: BaytiColors.text,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'السعر',
                hintStyle: const TextStyle(
                  color: BaytiColors.mutedSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                filled: true,
                fillColor: BaytiColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: BaytiColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: BaytiColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: widget.primary, width: 1.4),
                ),
              ),
              onSubmitted: (_) => _handleCheck(),
            ),
          ),
          widget.deleteButton(onTap: widget.onDelete),
        ],
      ),
    );
  }
}

class _WeekGroup {
  _WeekGroup({required this.start, required this.count, required this.total});
  final DateTime start;
  int count;
  double total;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.emoji, required this.message});
  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BaytiColors.itemCard,
                shape: BoxShape.circle,
                border: Border.all(color: BaytiColors.line),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9E9288),
                fontSize: 15,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}