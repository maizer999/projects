import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Memorize/review flow for one surah: shows it as one continuous flowing
/// mushaf-style text (not a card per ayah) and lets the user tap an ayah
/// they got wrong to mark it. The mark stays (persisted) until tapped
/// again to clear it, so coming back to the surah later shows exactly
/// which ayahs still need work — the counter in the surah list is just
/// how many ayahs are currently marked.
class SurahMemorizeScreen extends StatefulWidget {
  const SurahMemorizeScreen({
    super.key,
    required this.state,
    required this.surahNumber,
  });

  final AppState state;
  final int surahNumber;

  @override
  State<SurahMemorizeScreen> createState() => _SurahMemorizeScreenState();
}

class _SurahMemorizeScreenState extends State<SurahMemorizeScreen> {
  SurahDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _detail = null;
      _error = null;
    });
    try {
      final d = await widget.state.api.getSurah(
        widget.surahNumber,
        'quran-uthmani',
      );
      if (!mounted) return;
      setState(() => _detail = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final dark = s.darkMode;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) => Scaffold(
        backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
        appBar: AppBar(
          title: Text(
            _detail?.name ?? 'الحفظ',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            Builder(builder: (context) {
              final count = s.mistakeCountForSurah(widget.surahNumber);
              if (count == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmReset(context, count),
                icon:
                    const Icon(Icons.refresh, size: 18, color: AppColors.danger),
                label: Text(
                  'تصفير ($count)',
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }),
          ],
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير الأخطاء؟'),
        content: Text('رح يتم حذف علامات الأخطاء الـ$count لهاي السورة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.state.resetSurahMistakeCount(widget.surahNumber);
    }
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعذّر التحميل. تحقق من الاتصال.',
                  style: TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }
    final detail = _detail;
    if (detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final showBismillah = detail.number != 1 && detail.number != 9;
    return Column(
      children: [
        _hint(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _quranFrame(
              child: Column(
                children: [
                  if (showBismillah) _bismillah(),
                  _mushaf(detail, showBismillah),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.accent.withValues(alpha: 0.08),
      child: const Text(
        'اكبس على الآية اللي غلطت فيها لتعليمها — اكبس عليها كمان مرة لإلغاء العلامة',
        style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _bismillah() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 28,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _mushaf(SurahDetail detail, bool stripFirst) {
    final s = widget.state;
    final dark = s.darkMode;
    final textColor = dark ? AppColors.textDark : AppColors.textLight;
    const size = 24.0;
    final base = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: size,
      color: textColor,
      height: 2.0,
    );

    final spans = <InlineSpan>[];
    for (var i = 0; i < detail.ayahs.length; i++) {
      final a = detail.ayahs[i];
      var text = a.text;
      if (i == 0 && stripFirst) text = _stripBismillah(text);
      final marked = s.isSurahAyahMistake(widget.surahNumber, a.numberInSurah);

      final tokStyle = base.copyWith(
        backgroundColor: marked ? AppColors.danger.withValues(alpha: 0.18) : null,
        color: marked ? AppColors.danger : base.color,
      );

      final recognizer = TapGestureRecognizer()
        ..onTap = () =>
            s.toggleSurahAyahMistake(widget.surahNumber, a.numberInSurah);

      spans.add(TextSpan(text: '$text ', style: tokStyle, recognizer: recognizer));
      spans.add(TextSpan(
        text: '﴿${_toArabicDigits(a.numberInSurah)}﴾ ',
        style: base.copyWith(color: AppColors.gold, fontSize: size * 0.75),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              s.toggleSurahAyahMistake(widget.surahNumber, a.numberInSurah),
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
          BoxShadow(color: gold.withValues(alpha: 0.18), blurRadius: 14, spreadRadius: 1),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: gold.withValues(alpha: 0.55)),
        ),
        child: child,
      ),
    );
  }

  String _toArabicDigits(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : d[i];
    }).join();
  }

  // See the matching comment in reader_view.dart: some editions embed the
  // Bismillah inside ayah 1's own text, which showed up as it being
  // printed twice. We strip tashkeel to detect it reliably, then cut that
  // many words off the original (still-diacritised) text.
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
