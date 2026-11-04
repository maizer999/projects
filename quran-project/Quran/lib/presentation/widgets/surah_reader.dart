import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/font_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numerals.dart';
import '../../domain/entities/ayah.dart';
import '../providers/dependency_providers.dart';
import '../providers/mistakes_provider.dart';
import '../providers/player_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';

const String _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

/// Shows the current surah as flowing text in the chosen Arabic font.
///
/// Tap an ayah: in Listen mode it plays from there; in Memorize mode it
/// marks/unmarks it as a mistake.
class SurahReader extends ConsumerStatefulWidget {
  const SurahReader({super.key});

  @override
  ConsumerState<SurahReader> createState() => _SurahReaderState();
}

class _SurahReaderState extends ConsumerState<SurahReader> {
  final _scroll = ScrollController();
  final Map<int, TapGestureRecognizer> _recognizers = {};

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  /// One recognizer per ayah, reused across rebuilds. Callbacks read the
  /// latest state at tap time, so they never go stale.
  TapGestureRecognizer _recognizerFor(Ayah a) =>
      _recognizers.putIfAbsent(a.id, () => TapGestureRecognizer()..onTap = () => _onTap(a));

  Future<void> _onTap(Ayah a) async {
    if (ref.read(readerProvider).mode == ReaderMode.listen) {
      await ref.read(playerProvider.notifier).playFrom(a);
      return;
    }
    final marked = await ref
        .read(mistakesProvider.notifier)
        .toggle(surah: a.surah, ayahNumber: a.number);
    if (!mounted) return;
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
    final reader = ref.watch(readerProvider);
    final surah = ref.watch(surahsProvider)[reader.surahNumber - 1];
    final ayahs = ref.watch(getSurahAyahsProvider)(surah.number);
    final settings = ref.watch(settingsProvider);
    final font = arabicFontById(settings.fontId);
    final playing = ref.watch(playingAyahProvider);
    final mistakes = ref.watch(mistakesProvider)[surah.number] ?? const <int>{};
    final memorize = reader.mode == ReaderMode.memorize;

    // Recitation moved to another page → keep the reader's page in sync.
    ref.listen<int?>(playingAyahProvider.select((a) => a?.page), (_, page) {
      if (page != null) ref.read(readerProvider.notifier).setPage(page);
    });
    // Opening another surah starts at its top.
    ref.listen<int>(readerProvider.select((s) => s.surahNumber), (prev, next) {
      if (prev != next && _scroll.hasClients) _scroll.jumpTo(0);
    });

    final size = settings.mushafFontSize;
    final base = TextStyle(
      fontFamily: font.family,
      package: font.package,
      fontSize: size,
      height: 2.1,
      color: AppColors.textDark,
    );
    final markerStyle = base.copyWith(fontSize: size * 0.7, color: AppColors.gold);

    final spans = <InlineSpan>[];
    for (final a in ayahs) {
      final isPlaying = !memorize && playing?.id == a.id;
      final isMistake = memorize && mistakes.contains(a.number);
      final bg = isPlaying
          ? AppColors.accent.withValues(alpha: 0.30)
          : isMistake
              ? AppColors.danger.withValues(alpha: 0.18)
              : null;
      final recognizer = _recognizerFor(a);
      spans.add(TextSpan(
        text: '${a.text} ',
        style: base.copyWith(
          backgroundColor: bg,
          color: isMistake ? AppColors.danger : AppColors.textDark,
        ),
        recognizer: recognizer,
      ));
      spans.add(TextSpan(
        text: '﴿${toArabicDigits(a.number)}﴾ ',
        style: markerStyle.copyWith(backgroundColor: bg),
        recognizer: recognizer,
      ));
    }

    // Surah 1 has the Basmala as its first ayah; surah 9 has none.
    final showBasmala = surah.number != 1 && surah.number != 9;

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hint(memorize: memorize),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: AppColors.bg2Dark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                if (showBasmala)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _bismillah,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: base.copyWith(color: AppColors.gold, fontSize: size * 1.05),
                    ),
                  ),
                Text.rich(
                  TextSpan(children: spans),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.memorize});
  final bool memorize;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
