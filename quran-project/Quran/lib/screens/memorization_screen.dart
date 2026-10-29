import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/page_image.dart';
import 'page_viewer_screen.dart';

class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

enum _Filter { all, memorized, inProgress, notStarted, withMistakes }

class _MemorizationScreenState extends State<MemorizationScreen> {
  _Filter _filter = _Filter.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.state.darkMode;
    return Scaffold(
      backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('وضع الحفظ'),
        actions: [
          IconButton(
            tooltip: 'إعدادات مصدر الصور',
            icon: const Icon(Icons.link),
            onPressed: _editTemplate,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          return Column(
            children: [
              _summary(),
              _searchBar(),
              _filters(),
              const SizedBox(height: 4),
              Expanded(child: _list()),
            ],
          );
        },
      ),
    );
  }

  Widget _summary() {
    final s = widget.state;
    int memorized = 0, inProgress = 0, totalMistakes = 0;
    double sum = 0;
    for (final m in s.pageMemos.values) {
      if (m.memorized) {
        memorized++;
      } else if (m.percent > 0) {
        inProgress++;
      }
      sum += m.percent;
      totalMistakes += m.mistakes.length;
    }
    final overallPercent = (sum / AppState.quranPageCount).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0x338B5CF6), Color(0x3322D3EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الحفظ الإجمالي: $overallPercent%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: overallPercent / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _statChip('✓ محفوظة', '$memorized'),
                _statChip('قيد الحفظ', '$inProgress'),
                _statChip(
                  'الصفحات',
                  '${s.pageMemos.length} / ${AppState.quranPageCount}',
                ),
                _statChip('أخطاء', '$totalMistakes',
                    color: AppColors.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color ?? Colors.white.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color ?? Colors.white)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        keyboardType: TextInputType.number,
        onChanged: (v) => setState(() => _query = v.trim()),
        decoration: const InputDecoration(
          hintText: 'ابحث برقم الصفحة...',
          prefixIcon: Icon(Icons.search, size: 18),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _chip('الكل', _Filter.all),
          _chip('محفوظة', _Filter.memorized),
          _chip('قيد الحفظ', _Filter.inProgress),
          _chip('لم تبدأ', _Filter.notStarted),
          _chip('بها أخطاء', _Filter.withMistakes),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final active = _filter == f;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: active,
      onSelected: (_) => setState(() => _filter = f),
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(color: active ? Colors.white : null),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Iterable<int> _visiblePages() sync* {
    final q = _query;
    for (var p = 1; p <= AppState.quranPageCount; p++) {
      if (q.isNotEmpty && !p.toString().contains(q)) continue;
      final m = widget.state.pageMemos[p];
      switch (_filter) {
        case _Filter.all:
          break;
        case _Filter.memorized:
          if (m == null || !m.memorized) continue;
          break;
        case _Filter.inProgress:
          if (m == null || m.memorized || m.percent == 0) continue;
          break;
        case _Filter.notStarted:
          if (m != null && (m.memorized || m.percent > 0)) continue;
          break;
        case _Filter.withMistakes:
          if (m == null || m.mistakes.isEmpty) continue;
          break;
      }
      yield p;
    }
  }

  Widget _list() {
    final pages = _visiblePages().toList();
    if (pages.isEmpty) {
      return const Center(child: Text('لا توجد صفحات مطابقة.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: pages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _row(pages[i]),
    );
  }

  Widget _row(int page) {
    final s = widget.state;
    final memo = s.getPageMemo(page);
    final dark = s.darkMode;
    return Material(
      color: dark ? AppColors.panelDark : AppColors.panelLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PageViewerScreen(state: s, page: page),
        )),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: memo.memorized
                  ? AppColors.gold
                  : (dark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumb(s, page),
              const SizedBox(width: 12),
              Expanded(child: _info(s, page, memo)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(AppState s, int page) {
    final dark = s.darkMode;
    final pageColor =
        dark ? const Color(0xFF14183A) : const Color(0xFFFBF7EC);
    return Container(
      width: 72,
      height: 96,
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 12),
            child: PageImage(
              url: s.pageImageUrl(page),
              fit: BoxFit.contain,
              loading: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_) => Center(
                child: Text(
                  '$page',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 1,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.gold.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '$page',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(AppState s, int page, PageMemo memo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'صفحة $page',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (memo.mistakes.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Text(
                  '${memo.mistakes.length} خطأ',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Checkbox(
              value: memo.memorized,
              onChanged: (v) =>
                  s.setPageMemorized(page, v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 2),
            const Text('محفوظة', style: TextStyle(fontSize: 12)),
            const Spacer(),
            _stepperBtn(
              icon: Icons.remove,
              onTap: memo.percent > 0
                  ? () => s.setPagePercent(page, memo.percent - 5)
                  : null,
            ),
            SizedBox(
              width: 56,
              child: Center(
                child: Text(
                  '${memo.percent}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _stepperBtn(
              icon: Icons.add,
              onTap: memo.percent < 100
                  ? () => s.setPagePercent(page, memo.percent + 5)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: memo.percent / 100,
            minHeight: 6,
            backgroundColor:
                (s.darkMode ? AppColors.borderDark : AppColors.borderLight),
            valueColor: AlwaysStoppedAnimation<Color>(
              memo.memorized ? AppColors.gold : AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepperBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.state.darkMode
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
          color: enabled
              ? AppColors.accent.withValues(alpha: 0.10)
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.accent : AppColors.mutedDark,
        ),
      ),
    );
  }

  Future<void> _editTemplate() async {
    final ctrl =
        TextEditingController(text: widget.state.pageImageUrlTemplate);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رابط صور الصفحات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'استخدم {N} لرقم الصفحة (أو {N3} لثلاث خانات).\nالافتراضي: SVG مصحف المدينة من api.islamic.app.',
              style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'https://.../{N}.svg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await widget.state.setPageImageUrlTemplate(result);
    }
  }
}
