import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numerals.dart';
import '../../domain/entities/juz.dart';
import '../../domain/entities/surah.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/dependency_providers.dart';
import '../providers/favorites_provider.dart';
import '../providers/mistakes_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/reader_provider.dart';

/// 30 Juz, each expanding to its surahs. Tapping a surah opens its first
/// page in the reader. A segmented control at the top switches between the
/// full juz index and the user's favourites.
class JuzListPanel extends ConsumerStatefulWidget {
  const JuzListPanel({super.key, this.onSurahOpened});

  /// Lets the drawer close itself on narrow screens.
  final VoidCallback? onSurahOpened;

  @override
  ConsumerState<JuzListPanel> createState() => _JuzListPanelState();
}

class _JuzListPanelState extends ConsumerState<JuzListPanel> {
  final _search = TextEditingController();
  final _scrollCtrl = ScrollController();
  final Map<int, GlobalKey> _juzKeys = {};
  String _query = '';
  bool _didScrollToCurrent = false;

  @override
  void dispose() {
    _search.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _open(Surah surah) {
    ref.read(readerProvider.notifier).openSurah(surah.number);
    widget.onSurahOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(panelTabProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<PanelTab>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(
                  value: PanelTab.all,
                  icon: Icon(Icons.menu_book, size: 16),
                  label: Text(AppStrings.tabAll),
                ),
                ButtonSegment(
                  value: PanelTab.favorites,
                  icon: Icon(Icons.star_rounded, size: 16),
                  label: Text(AppStrings.tabFavorites),
                ),
                ButtonSegment(
                  value: PanelTab.bookmarks,
                  icon: Icon(Icons.bookmark_rounded, size: 16),
                  label: Text(AppStrings.tabBookmarks),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (s) =>
                  ref.read(panelTabProvider.notifier).set(s.first),
            ),
          ),
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
          Expanded(child: _body(tab)),
        ],
      ),
    );
  }

  Widget _body(PanelTab tab) {
    if (_query.trim().isNotEmpty) return _searchResults(tab);
    switch (tab) {
      case PanelTab.favorites:
        return _favoritesList();
      case PanelTab.bookmarks:
        return _bookmarksList();
      case PanelTab.all:
        return _juzList();
    }
  }

  Widget _searchResults(PanelTab tab) {
    var matches = ref.read(searchSurahsProvider)(_query);
    if (tab == PanelTab.favorites) {
      final favs = ref.watch(favoritesProvider);
      matches = matches.where((s) => favs.contains(s.number)).toList();
    } else if (tab == PanelTab.bookmarks) {
      final bookmarks = ref.watch(bookmarksProvider);
      matches = matches
          .where((s) => bookmarks.any((p) => p >= s.startPage && p <= s.endPage))
          .toList();
    }
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
    final currentSurah = ref.watch(readerProvider.select((r) => r.surahNumber));
    if (!_didScrollToCurrent) {
      _didScrollToCurrent = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToCurrentJuz(juzs, currentSurah),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(8),
      itemCount: juzs.length,
      itemBuilder: (_, i) {
        final juz = juzs[i];
        final isCurrent = juz.surahs.any((s) => s.number == currentSurah);
        final key = _juzKeys.putIfAbsent(juz.number, () => GlobalKey());
        return KeyedSubtree(
          key: key,
          child: _JuzTile(juz: juz, onOpen: _open, isCurrent: isCurrent),
        );
      },
    );
  }

  void _scrollToCurrentJuz(List<Juz> juzs, int currentSurah) {
    if (!mounted || !_scrollCtrl.hasClients) return;
    var idx = -1;
    for (var i = 0; i < juzs.length; i++) {
      if (juzs[i].surahs.any((s) => s.number == currentSurah)) {
        idx = i;
        break;
      }
    }
    if (idx <= 0) return;
    const approxTileHeight = 72.0;
    final target = (idx * approxTileHeight)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.jumpTo(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _juzKeys[juzs[idx].number]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.05,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  Widget _favoritesList() {
    final favs = ref.watch(favoritesProvider);
    final all = ref.watch(surahsProvider);
    final list = all.where((s) => favs.contains(s.number)).toList();
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            AppStrings.noFavorites,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedDark, height: 1.6),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) =>
          _SurahTile(surah: list[i], onTap: () => _open(list[i])),
    );
  }

  Widget _bookmarksList() {
    final bookmarks = ref.watch(bookmarksProvider);
    if (bookmarks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            AppStrings.noBookmarks,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedDark, height: 1.6),
          ),
        ),
      );
    }
    final pages = bookmarks.toList()..sort();
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: pages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) => _BookmarkTile(
        page: pages[i],
        onTap: () {
          ref.read(readerProvider.notifier).openPage(pages[i]);
          widget.onSurahOpened?.call();
        },
      ),
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

class _JuzTile extends StatefulWidget {
  const _JuzTile({
    required this.juz,
    required this.onOpen,
    required this.isCurrent,
  });
  final Juz juz;
  final void Function(Surah) onOpen;
  final bool isCurrent;

  @override
  State<_JuzTile> createState() => _JuzTileState();
}

class _JuzTileState extends State<_JuzTile> {
  final _expansion = ExpansibleController();

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          if (!_expansion.isExpanded) _expansion.expand();
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final juz = widget.juz;
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
            controller: _expansion,
            initiallyExpanded: widget.isCurrent,
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
                  child: _SurahTile(surah: s, onTap: () => widget.onOpen(s)),
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
    final isFav = ref.watch(isFavoriteProvider(surah.number));

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
              const SizedBox(width: 4),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    ref.read(favoritesProvider.notifier).toggle(surah.number),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: isFav ? AppColors.gold : AppColors.mutedDark,
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

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.page, required this.onTap});
  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(pageInfoProvider(page));
    final current = ref.watch(readerProvider.select((r) => r.page)) == page;
    return Material(
      color: current
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
              color: current ? AppColors.accent2 : AppColors.borderDark,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.pageLabel(toArabicDigits(page)),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    Text(
                      '${info.surah.nameArabic} · '
                      '${AppStrings.juzTitle(toArabicDigits(info.juz))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedDark,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    ref.read(bookmarksProvider.notifier).toggle(page),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.gold,
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
