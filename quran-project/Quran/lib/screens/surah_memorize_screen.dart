import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Memorize/review flow for one surah: shows its ayahs and lets the user
/// tap an ayah they got wrong, which bumps that surah's persistent
/// mistake counter (shown next to it in the surah list).
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
  int? _justTappedAyah;

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

  Future<void> _logMistake(int ayahNumber) async {
    await widget.state.incrementSurahMistake(widget.surahNumber);
    if (!mounted) return;
    setState(() => _justTappedAyah = ayahNumber);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _justTappedAyah == ayahNumber) {
        setState(() => _justTappedAyah = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final dark = s.darkMode;
    return Scaffold(
      backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text(_detail?.englishName ?? 'الحفظ'),
        actions: [
          AnimatedBuilder(
            animation: s,
            builder: (context, _) {
              final count = s.mistakeCountForSurah(widget.surahNumber);
              if (count == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => s.resetSurahMistakeCount(widget.surahNumber),
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.danger),
                label: Text(
                  'تصفير ($count)',
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
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
        'اكبس على الآية اللي غلطت فيها لتسجيل خطأ',
        style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _ayahTile(Ayah ayah) {
    final dark = widget.state.darkMode;
    final flashed = _justTappedAyah == ayah.numberInSurah;
    return Material(
      color: flashed
          ? AppColors.danger.withValues(alpha: 0.18)
          : (dark ? AppColors.panelDark : AppColors.panelLight),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _logMistake(ayah.numberInSurah),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: flashed
                  ? AppColors.danger
                  : (dark ? AppColors.borderDark : AppColors.borderLight),
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
                  border: Border.all(color: AppColors.gold),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${ayah.numberInSurah}',
                  style: const TextStyle(fontSize: 10, color: AppColors.gold),
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
