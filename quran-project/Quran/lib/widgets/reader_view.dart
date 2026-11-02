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
  int? _lastScrolledTo;

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
            'Failed to load Surah.\n${s.surahError}',
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
          _surahHeader(arabic),
          const SizedBox(height: 16),
          _quranFrame(
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

  Widget _surahHeader(SurahDetail s) {
    final mistakesInSurah = widget.state.mistakeCountForSurah(s.number);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.state.darkMode
              ? [const Color(0x332A1F5F), const Color(0x3301557E)]
              : [const Color(0x206D28D9), const Color(0x200891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.state.darkMode
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            s.name,
            textDirection: TextDirection.rtl,
            style: _arStyle(fontSize: 36, color: AppColors.gold, bold: true),
          ),
          const SizedBox(height: 4),
          Text(
            s.englishName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            s.englishNameTranslation,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _stat('Surah ${s.number}'),
              _stat('${s.numberOfAyahs} verses'),
              _stat(s.revelationType),
              if (mistakesInSurah > 0)
                _stat('$mistakesInSurah خطأ', color: AppColors.danger),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _actionButton(
                icon: Icons.play_arrow,
                label: 'استمع للسورة',
                onTap: () => widget.player.play(0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color ??
              (widget.state.darkMode
                  ? AppColors.borderDark
                  : AppColors.borderLight),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    Color? activeColor,
  }) {
    final color = active ? (activeColor ?? AppColors.accent) : null;
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color == null ? null : Colors.white),
      label: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: color == null ? null : Colors.white),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        side: BorderSide(
          color: color ??
              (widget.state.darkMode
                  ? AppColors.borderDark
                  : AppColors.borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onTap,
    );
  }

  Widget _quranFrame({required Widget child}) {
    final dark = widget.state.darkMode;
    final page = dark ? const Color(0xFF14183A) : const Color(0xFFFBF7EC);
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

      final recognizer = TapGestureRecognizer()
        ..onTap = () => _onAyahTap(i);

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
        recognizer: recognizer,
      ));
      spans.add(TextSpan(
        text: '﴿${_toArabicDigits(a.numberInSurah)}﴾ ',
        style: base.copyWith(
          color: AppColors.gold,
          fontSize: size * 0.75,
        ),
        recognizer: TapGestureRecognizer()..onTap = () => _onAyahTap(i),
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

  /// Tapping an ayah while reading just plays from there — marking
  /// mistakes happens in the dedicated Memorize screen for this surah.
  void _onAyahTap(int idx) => widget.player.play(idx);

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
            const Text('Welcome to the Al-Quran reader.'),
            const SizedBox(height: 6),
            const Text(
              'Pick a Surah from the list to start reading.',
              style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
            ),
          ],
        ),
      ),
    );
  }
}
