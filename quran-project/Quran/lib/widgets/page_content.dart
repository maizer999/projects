import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';

class QuranPageContent extends StatelessWidget {
  const QuranPageContent({
    super.key,
    required this.state,
    required this.page,
    this.fontSize = 22,
    this.showSurahHeaders = true,
    this.padding = const EdgeInsets.fromLTRB(14, 16, 14, 16),
  });

  final AppState state;
  final QuranPage page;
  final double fontSize;
  final bool showSurahHeaders;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = state.darkMode;
    final pageColor = dark ? const Color(0xFF14183A) : const Color(0xFFFBF7EC);
    const gold = AppColors.gold;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: pageColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: gold.withValues(alpha: 0.55)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    final groups = <List<PageAyah>>[];
    for (final a in page.ayahs) {
      if (groups.isEmpty || groups.last.first.surahNumber != a.surahNumber) {
        groups.add([a]);
      } else {
        groups.last.add(a);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'صفحة ${_toArabicDigits(page.number)}',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final g in groups) ...[
          if (showSurahHeaders) _surahHeader(g.first),
          _ayahsBlock(g),
          if (g != groups.last) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _surahHeader(PageAyah a) {
    final bismillah = a.numberInSurah == 1 &&
        a.surahNumber != 1 &&
        a.surahNumber != 9;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            a.surahName,
            textAlign: TextAlign.center,
            style: GoogleFonts.getFont(
              state.currentFont.family,
              fontSize: fontSize * 0.9,
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (bismillah)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                state.currentFont.family,
                fontSize: fontSize * 0.95,
                color: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _ayahsBlock(List<PageAyah> ayahs) {
    final color = state.darkMode ? AppColors.textDark : AppColors.textLight;
    final base = GoogleFonts.getFont(
      state.currentFont.family,
      fontSize: fontSize,
      color: color,
      height: 1.9,
    );

    final spans = <InlineSpan>[];
    for (final a in ayahs) {
      var text = a.text;
      if (a.numberInSurah == 1 &&
          a.surahNumber != 1 &&
          a.surahNumber != 9) {
        text = _stripBismillah(text);
      }
      spans.add(TextSpan(text: '$text ', style: base));
      spans.add(TextSpan(
        text: '﴿${_toArabicDigits(a.numberInSurah)}﴾ ',
        style: base.copyWith(
          color: AppColors.gold,
          fontSize: fontSize * 0.75,
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }

  static String _stripBismillah(String s) {
    final r1 = RegExp(r'^بِسْمِ\s*ٱللَّهِ\s*ٱلرَّحْمَـٰنِ\s*ٱلرَّحِيمِ\s*');
    final r2 = RegExp(r'^بِسْمِ\s*اللَّهِ\s*الرَّحْمَنِ\s*الرَّحِيمِ\s*');
    return s.replaceFirst(r1, '').replaceFirst(r2, '');
  }

  static String _toArabicDigits(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : d[i];
    }).join();
  }
}
