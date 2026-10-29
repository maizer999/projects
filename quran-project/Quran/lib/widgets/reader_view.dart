import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../services/player_controller.dart';
import '../theme.dart';
import 'ayah_actions_sheet.dart';

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
    return _buildContent(context, s.arabic!, s.translation);
  }

  Widget _buildContent(
    BuildContext context,
    SurahDetail arabic,
    SurahDetail? trans,
  ) {
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
          if (trans != null) ...[
            const SizedBox(height: 24),
            _translationHeader(),
            const SizedBox(height: 8),
            ..._translationRows(arabic, trans),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _surahHeader(SurahDetail s) {
    final mistakesInSurah =
        widget.state.mistakes.where((m) => m.surah == s.number).length;
    final saved = widget.state.isSurahSaved(s.number);

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
              _actionButton(
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                label: saved ? 'محفوظة' : 'احفظ السورة',
                active: saved,
                onTap: () => widget.state.toggleSavedSurah(s.number),
              ),
              _actionButton(
                icon: Icons.error_outline,
                label: 'وضع الأخطاء',
                active: widget.state.mistakeMode,
                onTap: widget.state.toggleMistakeMode,
                activeColor: AppColors.danger,
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
      final isBk = widget.state.isBookmarked(s.number, a.numberInSurah);
      final isMk = widget.state.isMistake(s.number, a.numberInSurah);

      final tokStyle = base.copyWith(
        backgroundColor: isPlaying
            ? AppColors.accent.withValues(alpha: 0.30)
            : isMk
                ? AppColors.danger.withValues(alpha: 0.18)
                : isBk
                    ? AppColors.gold.withValues(alpha: 0.14)
                    : null,
        color: isMk
            ? AppColors.danger
            : isBk
                ? AppColors.gold
                : base.color,
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

  Widget _translationHeader() {
    return Row(
      children: [
        Container(
          height: 1,
          width: 24,
          color: widget.state.darkMode
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
        const SizedBox(width: 8),
        Text(
          'Translation',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.state.darkMode
                ? AppColors.mutedDark
                : AppColors.mutedLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: widget.state.darkMode
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
      ],
    );
  }

  List<Widget> _translationRows(SurahDetail arabic, SurahDetail trans) {
    final rows = <Widget>[];
    for (var i = 0; i < arabic.ayahs.length; i++) {
      final a = arabic.ayahs[i];
      final t = trans.ayahs[i];
      final isPlaying = widget.state.currentAyahIdx == i;
      final isBk = widget.state.isBookmarked(arabic.number, a.numberInSurah);
      final isMk = widget.state.isMistake(arabic.number, a.numberInSurah);

      rows.add(Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.accent.withValues(alpha: 0.14)
              : isMk
                  ? AppColors.danger.withValues(alpha: 0.08)
                  : widget.state.darkMode
                      ? AppColors.panelDark
                      : AppColors.panelLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPlaying
                ? AppColors.accent
                : widget.state.darkMode
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Text(
                '${a.numberInSurah}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.text,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _miniBtn(
                        'Play',
                        Icons.play_arrow,
                        () => widget.player.play(i),
                      ),
                      _miniBtn(
                        isBk ? 'Saved' : 'Save',
                        isBk ? Icons.bookmark : Icons.bookmark_border,
                        () => widget.state
                            .toggleBookmark(arabic.number, a.numberInSurah),
                        active: isBk,
                      ),
                      _miniBtn(
                        isMk ? 'خطأ' : 'خطأ؟',
                        Icons.close,
                        () => widget.state
                            .toggleMistake(arabic.number, a.numberInSurah),
                        active: isMk,
                        activeColor: AppColors.danger,
                      ),
                      _miniBtn(
                        'Copy',
                        Icons.copy,
                        () => _copyAyah(a, t),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    return rows;
  }

  Widget _miniBtn(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
    Color? activeColor,
  }) {
    final bg = active ? (activeColor ?? AppColors.accent) : null;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: bg ??
                (widget.state.darkMode
                    ? AppColors.borderDark
                    : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: bg == null ? null : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: bg == null ? null : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAyahTap(int idx) {
    final s = widget.state;
    final arabic = s.arabic;
    if (arabic == null) return;
    final a = arabic.ayahs[idx];
    if (s.mistakeMode) {
      s.toggleMistake(arabic.number, a.numberInSurah);
      return;
    }
    showAyahActions(
      context,
      state: s,
      player: widget.player,
      ayahIdx: idx,
    );
  }

  Future<void> _copyAyah(Ayah a, Ayah t) async {
    final s = widget.state.arabic!;
    final text =
        '${a.text}\n\n${t.text}\n\n— Surah ${s.englishName} (${s.number}:${a.numberInSurah})';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  TextStyle _arStyle({
    required double fontSize,
    Color? color,
    bool bold = false,
  }) {
    final family = widget.state.currentFont.family;
    return GoogleFonts.getFont(
      family,
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

  String _stripBismillah(String s) {
    final r1 = RegExp(r'^بِسْمِ\s*ٱللَّهِ\s*ٱلرَّحْمَـٰنِ\s*ٱلرَّحِيمِ\s*');
    final r2 = RegExp(r'^بِسْمِ\s*اللَّهِ\s*الرَّحْمَنِ\s*الرَّحِيمِ\s*');
    return s.replaceFirst(r1, '').replaceFirst(r2, '');
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
              style: GoogleFonts.amiriQuran(
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
