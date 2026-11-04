import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numerals.dart';
import '../../domain/entities/juz.dart';
import '../../domain/entities/surah.dart';
import '../providers/dependency_providers.dart';
import '../providers/mistakes_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/reader_provider.dart';

/// 30 Juz, each expanding to its surahs. Tapping a surah opens its first
/// page in the reader.
class JuzListPanel extends ConsumerStatefulWidget {
  const JuzListPanel({super.key, this.onSurahOpened});

  /// Lets the drawer close itself on narrow screens.
  final VoidCallback? onSurahOpened;

  @override
  ConsumerState<JuzListPanel> createState() => _JuzListPanelState();
}

class _JuzListPanelState extends ConsumerState<JuzListPanel> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Surah surah) {
    ref.read(readerProvider.notifier).openSurah(surah.number);
    widget.onSurahOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _query.trim().isEmpty ? _juzList() : _searchResults(),
          ),
        ],
      ),
    );
  }

  Widget _searchResults() {
    final matches = ref.read(searchSurahsProvider)(_query);
    if (matches.isEmpty) return const Center(child: Text(AppStrings.noResults));
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) =>
          _SurahTile(surah: matches[i], onTap: () => _open(matches[i])),
    );
  }

  Widget _juzList() {
    final juzs = ref.watch(juzIndexProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: juzs.length,
      itemBuilder: (_, i) => _JuzTile(juz: juzs[i], onOpen: _open),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent, AppColors.accent2],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text(
            'ق',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConstants.appTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                AppStrings.appSubtitle,
                style: TextStyle(fontSize: 11, color: AppColors.mutedDark),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.juz, required this.onOpen});
  final Juz juz;
  final void Function(Surah) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.panelDark,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('juz_${juz.number}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bg2Dark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                toArabicDigits(juz.number),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              AppStrings.juzTitle(toArabicDigits(juz.number)),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              juz.surahs.map((s) => s.nameArabic).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.mutedDark),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            children: [
              for (final s in juz.surahs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SurahTile(surah: s, onTap: () => onOpen(s)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends ConsumerWidget {
  const _SurahTile({required this.surah, required this.onTap});
  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(readerProvider.select((r) => r.surahNumber)) == surah.number;
    final mistakes = ref.watch(mistakeCountProvider(surah.number));

    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.18)
          : AppColors.bg2Dark,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent2 : AppColors.borderDark,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  toArabicDigits(surah.number),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  surah.nameArabic,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
              if (mistakes > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    toArabicDigits(mistakes),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                AppStrings.pageLabel(toArabicDigits(surah.startPage)),
                style: TextStyle(fontSize: 10, color: AppColors.mutedDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
