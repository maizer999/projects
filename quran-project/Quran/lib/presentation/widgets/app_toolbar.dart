import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numerals.dart';
import '../providers/mistakes_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';
import 'settings_sheet.dart';

class AppToolbar extends ConsumerWidget {
  const AppToolbar({super.key, this.onOpenDrawer});
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reader = ref.watch(readerProvider);
    final info = ref.watch(pageInfoProvider(reader.page));
    final surah = ref.watch(surahsProvider)[reader.surahNumber - 1];
    final mistakes = ref.watch(mistakeCountProvider(reader.surahNumber));
    final memorize = reader.mode == ReaderMode.memorize;
    final fontSize = ref.watch(settingsProvider.select((s) => s.mushafFontSize));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderDark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (onOpenDrawer != null)
                  IconButton(icon: const Icon(Icons.menu), onPressed: onOpenDrawer),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surah.nameArabic,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${AppStrings.juzTitle(toArabicDigits(info.juz))} · '
                        '${AppStrings.pageLabel(toArabicDigits(info.page))}',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedDark),
                      ),
                    ],
                  ),
                ),
                if (memorize && mistakes > 0)
                  TextButton.icon(
                    onPressed: () => _confirmReset(context, ref, reader.surahNumber, mistakes),
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.danger),
                    label: Text(
                      AppStrings.resetMistakes(toArabicDigits(mistakes)),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                IconButton.filledTonal(
                  tooltip: AppStrings.fontDecrease,
                  iconSize: 26,
                  icon: const Icon(Icons.text_decrease),
                  onPressed: fontSize > AppConstants.mushafFontMin
                      ? () => ref
                          .read(settingsProvider.notifier)
                          .bumpFontSize(-AppConstants.mushafFontStep)
                      : null,
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: AppStrings.fontIncrease,
                  iconSize: 26,
                  icon: const Icon(Icons.text_increase),
                  onPressed: fontSize < AppConstants.mushafFontMax
                      ? () => ref
                          .read(settingsProvider.notifier)
                          .bumpFontSize(AppConstants.mushafFontStep)
                      : null,
                ),
                IconButton(
                  tooltip: AppStrings.settingsTitle,
                  icon: const Icon(Icons.tune),
                  onPressed: () => showSettingsSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ReaderMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ReaderMode.listen,
                    icon: Icon(Icons.headphones_outlined, size: 18),
                    label: Text(AppStrings.modeListen),
                  ),
                  ButtonSegment(
                    value: ReaderMode.memorize,
                    icon: Icon(Icons.edit_note, size: 18),
                    label: Text(AppStrings.modeMemorize),
                  ),
                ],
                selected: {reader.mode},
                onSelectionChanged: (s) => ref.read(readerProvider.notifier).setMode(s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, int surah, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(AppStrings.resetMistakesTitle),
          content: Text(AppStrings.resetMistakesBody(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text(AppStrings.reset),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await ref.read(mistakesProvider.notifier).reset(surah);
  }
}
