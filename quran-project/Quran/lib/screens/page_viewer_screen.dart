import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/page_content.dart';
import '../widgets/page_image.dart';

class PageViewerScreen extends StatefulWidget {
  const PageViewerScreen({super.key, required this.state, required this.page});
  final AppState state;
  final int page;

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  late int _page = widget.page;
  bool _markMode = true;
  bool _asImage = true;
  double _fontSize = 22;
  final _pageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final dark = s.darkMode;
    return Scaffold(
      backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text('صفحة $_page'),
        actions: [
          IconButton(
            tooltip: _asImage ? 'عرض كنص' : 'عرض كصورة',
            icon: Icon(_asImage ? Icons.text_snippet : Icons.image),
            onPressed: () => setState(() => _asImage = !_asImage),
          ),
          IconButton(
            tooltip:
                _markMode ? 'إيقاف وضع التعليم' : 'تفعيل وضع التعليم',
            icon: Icon(
              _markMode ? Icons.edit : Icons.edit_off,
              color: _markMode ? AppColors.danger : null,
            ),
            onPressed: () => setState(() => _markMode = !_markMode),
          ),
          AnimatedBuilder(
            animation: s,
            builder: (_, __) {
              final memo = s.getPageMemo(_page);
              return IconButton(
                tooltip: 'مسح الأخطاء',
                icon: const Icon(Icons.clear_all),
                onPressed: memo.mistakes.isEmpty
                    ? null
                    : () => s.clearPageMistakes(_page),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: s,
        builder: (ctx, _) {
          final memo = s.getPageMemo(_page);
          return Column(
            children: [
              Expanded(child: _pageArea(s, memo)),
              _bottomBar(s, memo),
            ],
          );
        },
      ),
    );
  }

  Widget _pageArea(AppState s, PageMemo memo) {
    if (_asImage) return _imagePage(s, memo);
    return FutureBuilder<QuranPage>(
      future: s.getQuranPage(_page),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off,
                      color: AppColors.mutedDark, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    'تعذّر تحميل الصفحة $_page',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snap.error ?? ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }
        return _interactivePage(s, snap.data!, memo);
      },
    );
  }

  Widget _imagePage(AppState s, PageMemo memo) {
    final dark = s.darkMode;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.18),
              blurRadius: 12,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF14183A) : const Color(0xFFFBF7EC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
          ),
          clipBehavior: Clip.hardEdge,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _markMode
                ? (d) {
                    final box = _pageKey.currentContext?.findRenderObject()
                        as RenderBox?;
                    if (box == null) return;
                    final sz = box.size;
                    final x = (d.localPosition.dx / sz.width).clamp(0.0, 1.0);
                    final y =
                        (d.localPosition.dy / sz.height).clamp(0.0, 1.0);
                    s.togglePageMistakeAt(_page, x, y);
                  }
                : null,
            child: Stack(
              key: _pageKey,
              children: [
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  panEnabled: !_markMode,
                  scaleEnabled: !_markMode,
                  child: PageImage(
                    url: s.pageImageUrl(_page),
                    fit: BoxFit.contain,
                    loading: const Center(child: CircularProgressIndicator()),
                    error: (e) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image,
                              color: AppColors.mutedDark, size: 42),
                          const SizedBox(height: 8),
                          Text('تعذّر تحميل صورة الصفحة $_page',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            s.pageImageUrl(_page),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.mutedDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.text_snippet, size: 16),
                            label: const Text('عرض كنص'),
                            onPressed: () =>
                                setState(() => _asImage = false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _MistakePainter(marks: memo.mistakes),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _interactivePage(AppState s, QuranPage page, PageMemo memo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _markMode
            ? (d) {
                final box =
                    _pageKey.currentContext?.findRenderObject() as RenderBox?;
                if (box == null) return;
                final sz = box.size;
                final x = (d.localPosition.dx / sz.width).clamp(0.0, 1.0);
                final y = (d.localPosition.dy / sz.height).clamp(0.0, 1.0);
                s.togglePageMistakeAt(_page, x, y);
              }
            : null,
        child: Stack(
          key: _pageKey,
          children: [
            QuranPageContent(
              state: s,
              page: page,
              fontSize: _fontSize,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MistakePainter(marks: memo.mistakes),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(AppState s, PageMemo memo) {
    final dark = s.darkMode;
    return Container(
      color: dark ? AppColors.bg2Dark : AppColors.panelLight,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page > 1
                      ? () => setState(() => _page--)
                      : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'صفحة $_page من ${AppState.quranPageCount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${memo.mistakes.length} خطأ · ${memo.percent}% محفوظ',
                        style: TextStyle(
                          color: memo.mistakes.isEmpty
                              ? AppColors.mutedDark
                              : AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page < AppState.quranPageCount
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: memo.memorized,
                  onChanged: (v) => s.setPageMemorized(_page, v ?? false),
                ),
                const Text('محفوظة', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: memo.percent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${memo.percent}%',
                    onChanged: (v) => s.setPagePercent(_page, v.round()),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${memo.percent}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.text_fields, size: 16),
                const SizedBox(width: 6),
                const Text('حجم الخط', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 14,
                    max: 40,
                    divisions: 13,
                    label: _fontSize.round().toString(),
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${_fontSize.round()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (_markMode)
              const Text(
                'اضغط على الصفحة لتعليم مكان الخطأ. اضغط مرة ثانية للإزالة.',
                style: TextStyle(color: AppColors.mutedDark, fontSize: 11),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _MistakePainter extends CustomPainter {
  _MistakePainter({required this.marks});
  final List<PageMistakeMark> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in marks) {
      final c = Offset(m.x * size.width, m.y * size.height);
      canvas.drawCircle(c, 14, fill);
      canvas.drawCircle(c, 14, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MistakePainter oldDelegate) =>
      oldDelegate.marks != marks;
}
