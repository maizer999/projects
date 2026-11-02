import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class ReaderView extends StatefulWidget {
  const ReaderView({super.key, required this.state, required this.player});
  final AppState state;
  final PlayerController player;

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final _scrollCtrl = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  final Map<int, DateTime> _tapDownAt = {};
  int? _lastScrolledTo;
  static const _longPressThreshold = Duration(milliseconds: 420);

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final idx = widget.state.currentAyahIdx;
    if (idx >= 0 && idx != _lastScrolledTo) {
      _lastScrolledTo = idx;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
    } else if (idx < 0) {
      _lastScrolledTo = null;
    }
  }

  void _scrollTo(int idx) {
    final key = _ayahKeys[idx];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        alignment: 0.3,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (s.loadingSurah) {
      return const _Skeletons();
    }
    if (s.surahError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'تعذّر تحميل السورة.\n${s.surahError}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    }
    if (s.arabic == null) {
      return const _Welcome();
    }
    return _buildContent(context, s.arabic!);
  }

  Widget _buildContent(BuildContext context, SurahDetail arabic) {
    final showBismillah = arabic.number != 1 && arabic.number != 9;

    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hint(),
          const SizedBox(height: 10),
          _page(
            child: Column(
              children: [
                if (showBismillah) _bismillah(),
                _mushaf(arabic, showBismillah),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _hint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'اضغط على الآية لتسمعها من هناك — اضغط مطوّلًا عليها لتعليمها كخطأ',
        style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// The reading page itself: the ornate gold-framed "mushaf" look when
  /// enabled in Settings, or a plain minimal card when the user prefers a
  /// cleaner, distraction-free page.
  Widget _page({required Widget child}) {
    if (widget.state.ornateFrame) return _quranFrame(child: child);
    final dark = widget.state.darkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: dark ? AppColors.bg2Dark : AppColors.panelLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }

  Widget _quranFrame({required Widget child}) {
    final dark = widget.state.darkMode;
    final page = dark ? AppColors.pageDark : AppColors.pageLight;
    const gold = AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: gold.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -4, left: -4, child: _frameCorner()),
            Positioned(
              top: -4,
              right: -4,
              child: Transform.flip(flipX: true, child: _frameCorner()),
            ),
            Positioned(
              bottom: -4,
              left: -4,
              child: Transform.flip(flipY: true, child: _frameCorner()),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Transform.rotate(angle: 3.14159, child: _frameCorner()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _frameCorner() {
    const gold = AppColors.gold;
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CornerPainter(color: gold),
      ),
    );
  }

  Widget _bismillah() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: _arStyle(fontSize: 32, color: AppColors.gold),
        ),
      ),
    );
  }

  Widget _mushaf(SurahDetail s, bool stripFirst) {
    _ayahKeys.clear();
    final spans = <InlineSpan>[];
    final size = widget.state.arSize;
    final base = _arStyle(fontSize: size, color: _textColor());

    for (var i = 0; i < s.ayahs.length; i++) {
      final a = s.ayahs[i];
      var text = a.text;
      if (i == 0 && stripFirst) text = _stripBismillah(text);
      final isPlaying = widget.state.currentAyahIdx == i;
      final isMk =
          widget.state.isSurahAyahMistake(s.number, a.numberInSurah);

      final tokStyle = base.copyWith(
        backgroundColor: isPlaying
            ? AppColors.accent.withValues(alpha: 0.30)
            : isMk
                ? AppColors.danger.withValues(alpha: 0.18)
                : null,
        color: isMk ? AppColors.danger : base.color,
      );

      final key = GlobalKey();
      _ayahKeys[i] = key;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: SizedBox.shrink(key: key),
      ));
      spans.add(TextSpan(
        text: '$text ',
        style: tokStyle,
        recognizer: _ayahRecognizer(s.number, a.numberInSurah, i),
      ));
      spans.add(TextSpan(
        text: '﴿${_toArabicDigits(a.numberInSurah)}﴾ ',
        style: base.copyWith(
          color: AppColors.gold,
          fontSize: size * 0.75,
        ),
        recognizer: _ayahRecognizer(s.number, a.numberInSurah, i),
      ));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  /// A quick tap on an ayah plays it; a long press (press-and-hold) toggles
  /// it as a mistake. Both live on one TapGestureRecognizer — tap duration
  /// decides which action fires, so there's no gesture-arena conflict with
  /// a separate long-press recognizer on the same span.
  GestureRecognizer _ayahRecognizer(int surahNumber, int ayahNumber, int idx) {
    return TapGestureRecognizer()
      ..onTapDown = (_) { _tapDownAt[idx] = DateTime.now(); }
      ..onTapCancel = () { _tapDownAt.remove(idx); }
      ..onTapUp = (_) {
        final down = _tapDownAt.remove(idx);
        final isLongPress = down != null &&
            DateTime.now().difference(down) >= _longPressThreshold;
        if (isLongPress) {
          widget.state.toggleSurahAyahMistake(surahNumber, ayahNumber);
        } else {
          widget.player.play(idx);
        }
      };
  }

  TextStyle _arStyle({
    required double fontSize,
    Color? color,
    bool bold = false,
  }) {
    return TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: fontSize,
      color: color ?? _textColor(),
      height: 2.0,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
  }

  Color _textColor() =>
      widget.state.darkMode ? AppColors.textDark : AppColors.textLight;

  String _toArabicDigits(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : d[i];
    }).join();
  }

  // Some editions embed the Bismillah inside ayah 1's own text (in addition
  // to us drawing it separately above the surah), which showed up as it
  // being printed twice. Diacritics differ slightly between editions, so
  // instead of matching an exact string we strip tashkeel to check whether
  // the ayah *starts* with "بسم الله الرحمن الرحيم", then cut that many
  // whitespace-separated words off the original (still-diacritised) text.
  String _stripBismillah(String s) {
    final noTashkeel =
        s.replaceAll(RegExp(r'[ً-ٰٟۖ-ۭ]'), '');
    final normalized = noTashkeel.replaceAll('ٱ', 'ا');
    const bismillah = 'بسم الله الرحمن الرحيم';
    if (!normalized.startsWith(bismillah)) return s;
    final wordCount = bismillah.split(' ').length;
    var i = 0;
    for (var w = 0; w < wordCount && i < s.length; w++) {
      while (i < s.length && s[i] != ' ') {
        i++;
      }
      while (i < s.length && s[i] == ' ') {
        i++;
      }
    }
    return s.substring(i);
  }
}

class _Skeletons extends StatelessWidget {
  const _Skeletons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: List.generate(
          6,
          (_) => Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.6)
      ..lineTo(0, 0)
      ..lineTo(w * 0.6, 0);
    canvas.drawPath(path, stroke);
    final inner = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..lineTo(w * 0.25, w * 0.25)
      ..lineTo(w * 0.55, h * 0.25);
    canvas.drawPath(inner, stroke);
    canvas.drawCircle(Offset(w * 0.25, h * 0.25), 1.6, fill);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 44,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('مرحبًا بك في تطبيق القرآن الكريم'),
            const SizedBox(height: 6),
            Text(
              'اختر سورة من القائمة للبدء',
              style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
            ),
          ],
        ),
      ),
    );
  }
}
