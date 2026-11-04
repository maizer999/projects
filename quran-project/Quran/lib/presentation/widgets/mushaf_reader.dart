import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushaf_text/mushaf_text.dart' as mt;

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/dependency_providers.dart';
import '../providers/highlight_provider.dart';
import '../providers/mistakes_provider.dart';
import '../providers/player_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';

/// The whole Mushaf as a right-to-left PageView (604 pages).
class MushafReader extends ConsumerStatefulWidget {
  const MushafReader({super.key});

  @override
  ConsumerState<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends ConsumerState<MushafReader> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: ref.read(readerProvider).page - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (!_controller.hasClients) return;
    final current = (_controller.page ?? _controller.initialPage.toDouble()).round();
    final target = page - 1;
    if (current == target) return;
    // Adjacent pages slide; long jumps (opening a surah) jump straight there
    // so onPageChanged doesn't fire for every page in between.
    if ((current - target).abs() == 1) {
      _controller.animateToPage(
        target,
        duration: AppConstants.pageTurnDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _controller.jumpToPage(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reader state → PageView (surah opened from the list).
    ref.listen<int>(readerProvider.select((s) => s.page), (_, page) => _goTo(page));

    // Recitation moved to another page → turn the page.
    ref.listen<int?>(playingAyahProvider.select((a) => a?.page), (_, page) {
      if (page != null) ref.read(readerProvider.notifier).setPage(page);
    });

    final mode = ref.watch(readerProvider.select((s) => s.mode));

    return Column(
      children: [
        _ModeHint(mode: mode),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _controller,
              itemCount: AppConstants.totalPages,
              onPageChanged: (i) => ref.read(readerProvider.notifier).setPage(i + 1),
              itemBuilder: (_, i) => _MushafPageItem(page: i + 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeHint extends StatelessWidget {
  const _ModeHint({required this.mode});
  final ReaderMode mode;

  @override
  Widget build(BuildContext context) {
    final memorize = mode == ReaderMode.memorize;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (memorize ? AppColors.danger : AppColors.accent).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        memorize ? AppStrings.memorizeHint : AppStrings.listenHint,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
      ),
    );
  }
}

class _MushafPageItem extends ConsumerStatefulWidget {
  const _MushafPageItem({required this.page});
  final int page;

  @override
  ConsumerState<_MushafPageItem> createState() => _MushafPageItemState();
}

class _MushafPageItemState extends ConsumerState<_MushafPageItem> {

  mt.MushafColors _colors(bool memorize) => mt.MushafColors.dark.copyWith(
        paper: AppColors.pageDark,
        ink: AppColors.textDark,
        accent: AppColors.gold,
        banner: AppColors.bg2Dark,
        gold: AppColors.gold,
        highlight: Color.alphaBlend(
          (memorize ? AppColors.danger : AppColors.accent2).withValues(alpha: 0.35),
          AppColors.pageDark,
        ),
      );

  Future<void> _onAyahTap(BuildContext context, int ayahId) async {
    final ayah = ref.read(getAyahByIdProvider)(ayahId);
    if (ayah == null) return;
    if (ref.read(readerProvider).mode == ReaderMode.listen) {
      await ref.read(playerProvider.notifier).playFrom(ayah);
      return;
    }
    final marked = await ref
        .read(mistakesProvider.notifier)
        .toggle(surah: ayah.surah, ayahNumber: ayah.number);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          marked ? AppStrings.markedAsMistake : AppStrings.unmarkedMistake,
          textDirection: TextDirection.rtl,
        ),
        duration: AppConstants.snackBarDuration,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final memorize = ref.watch(readerProvider.select((s) => s.mode)) == ReaderMode.memorize;
    final highlighted = ref.watch(highlightedAyahsProvider);
    final colors = _colors(memorize);

    final pageView = ColoredBox(
      color: colors.paper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: mt.MushafPage(
          page: widget.page,
          colors: colors,
          tajweed: settings.tajweed,
          maxFontSize: AppConstants.mushafFontDefault,
          highlightedAyahs: highlighted,
          onAyahTap: (id) => _onAyahTap(context, id),
        ),
      ),
    );

    final framed = settings.ornateFrame
        ? _OrnateFrame(child: pageView)
        : _PlainFrame(child: pageView);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: framed,
    );
  }
}

class _PlainFrame extends StatelessWidget {
  const _PlainFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(13), child: child),
      );
}

class _OrnateFrame extends StatelessWidget {
  const _OrnateFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const gold = AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold, width: 2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: gold.withValues(alpha: 0.55)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(1),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
          ),
          const Positioned(top: 0, left: 0, child: _Corner()),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.flip(flipX: true, child: const _Corner()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.flip(flipY: true, child: const _Corner()),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.flip(flipX: true, flipY: true, child: const _Corner()),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _CornerPainter(AppColors.gold)),
      );
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.6)
        ..lineTo(0, 0)
        ..lineTo(w * 0.6, 0),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.25, h * 0.55)
        ..lineTo(w * 0.25, h * 0.25)
        ..lineTo(w * 0.55, h * 0.25),
      stroke,
    );
    canvas.drawCircle(Offset(w * 0.25, h * 0.25), 1.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.color != color;
}
