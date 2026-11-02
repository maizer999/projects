import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Memorize/review flow for one surah: shows its ayahs and lets the user
/// tap an ayah they got wrong to mark it. The mark stays (persisted) until
/// tapped again to clear it, so coming back to the surah later shows
/// exactly which ayahs still need work — the counter in the surah list is
/// just how many ayahs are currently marked.
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
          title: Text(_detail?.englishName ?? 'الحفظ'),
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
    return Column(
      children: [
        _hint(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: detail.ayahs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ayahTile(detail.ayahs[i]),
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

  Widget _ayahTile(Ayah ayah) {
    final s = widget.state;
    final dark = s.darkMode;
    final marked = s.isSurahAyahMistake(widget.surahNumber, ayah.numberInSurah);
    return Material(
      color: marked
          ? AppColors.danger.withValues(alpha: 0.14)
          : (dark ? AppColors.panelDark : AppColors.panelLight),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            s.toggleSurahAyahMistake(widget.surahNumber, ayah.numberInSurah),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: marked
                  ? AppColors.danger
                  : (dark ? AppColors.borderDark : AppColors.borderLight),
              width: marked ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(left: 8, top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marked ? AppColors.danger : null,
                  border: Border.all(
                    color: marked ? AppColors.danger : AppColors.gold,
                  ),
                ),
                alignment: Alignment.center,
                child: marked
                    ? const Icon(Icons.close, size: 14, color: Colors.white)
                    : Text(
                        '${ayah.numberInSurah}',
                        style:
                            const TextStyle(fontSize: 10, color: AppColors.gold),
                      ),
              ),
              Expanded(
                child: Text(
                  ayah.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 24,
                    height: 1.9,
                    color: dark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
