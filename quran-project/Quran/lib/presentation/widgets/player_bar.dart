import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_numerals.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/player_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/reader_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/contact_screen.dart';

/// Bottom bar with two states:
/// - collapsed (default): a toolbar with "استماع" and "تواصل معنا".
/// - expanded: tapping "استماع" starts recitation and shows the full player
///   (play/pause, stop, previous/next, speed, progress). The ⌄ button goes
///   back to the toolbar; audio keeps playing.
class PlayerBar extends ConsumerStatefulWidget {
  const PlayerBar({super.key});

  @override
  ConsumerState<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends ConsumerState<PlayerBar> {
  bool _expanded = false;
  int _navIndex = _listenIndex;

  // Fixed order of the curved nav items. Keep "listen" centered so the
  // raised circle sits over the main play action by default.
  static const _favIndex = 0;
  static const _bookmarkIndex = 1;
  static const _listenIndex = 2;
  static const _contactIndex = 3;

  void _openPlayer() {
    setState(() {
      _expanded = true;
      _navIndex = _listenIndex;
    });
    final s = ref.read(playerProvider);
    if (!s.playing && !s.loading) ref.read(playerProvider.notifier).toggle();
  }

  void _openContact() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
      );

  void _openFavorites() {
    ref.read(panelTabProvider.notifier).set(PanelTab.favorites);
    Scaffold.maybeOf(context)?.openEndDrawer();
  }

  Future<void> _toggleBookmark() async {
    final page = ref.read(readerProvider).page;
    final wasBookmarked = ref.read(bookmarksProvider).contains(page);
    await ref.read(bookmarksProvider.notifier).toggle(page);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          wasBookmarked ? AppStrings.bookmarkRemoved : AppStrings.bookmarkAdded,
          textDirection: TextDirection.rtl,
        ),
        duration: AppConstants.snackBarDuration,
      ));
  }

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case _favIndex:
        _openFavorites();
      case _bookmarkIndex:
        _toggleBookmark();
      case _listenIndex:
        _openPlayer();
      case _contactIndex:
        _openContact();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((s) => s.themePresetId));
    ref.listen<String?>(playerProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error, textDirection: TextDirection.rtl),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: AppStrings.retry,
            onPressed: () => ref.read(playerProvider.notifier).retry(),
          ),
        ));
    });
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: AppColors.bg2Dark,
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: AppConstants.playerToggleDuration,
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: _expanded
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.borderDark)),
                    ),
                    child: _ExpandedPlayer(
                      onCollapse: () => setState(() => _expanded = false),
                    ),
                  )
                : _CurvedBottomBar(
                    index: _navIndex,
                    onTap: _onNavTap,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CurvedBottomBar extends ConsumerWidget {
  const _CurvedBottomBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerProvider.select((s) => s.playing));
    final loading = ref.watch(playerProvider.select((s) => s.loading));
    final page = ref.watch(readerProvider.select((s) => s.page));
    final bookmarked = ref.watch(isBookmarkedProvider(page));

    const iconSize = 26.0;
    final onBar = Colors.white;

    return CurvedNavigationBar(
      index: index,
      height: 65,
      color: AppColors.accent,
      buttonBackgroundColor: AppColors.accent2,
      backgroundColor: AppColors.bg2Dark,
      animationDuration: const Duration(milliseconds: 350),
      animationCurve: Curves.easeOutCubic,
      onTap: onTap,
      items: [
        Icon(Icons.star_rounded, size: iconSize, color: onBar),
        Icon(
          bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: iconSize,
          color: onBar,
        ),
        loading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(strokeWidth: 3, color: onBar),
              )
            : Icon(
                playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                size: iconSize + 2,
                color: onBar,
              ),
        Icon(Icons.support_agent_rounded, size: iconSize, color: onBar),
      ],
    );
  }
}

class _ExpandedPlayer extends ConsumerWidget {
  const _ExpandedPlayer({required this.onCollapse});
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final p = ref.read(playerProvider.notifier);
    final reciter = ref.watch(currentReciterProvider);
    final current = s.current;
    final surahName =
        current == null ? '' : ref.watch(surahsProvider)[current.surah - 1].nameArabic;
    final muted = TextStyle(fontSize: 13, color: AppColors.mutedDark);
    final total = s.queue.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      surahName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    Text(reciter.name, overflow: TextOverflow.ellipsis, style: muted),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.hidePlayer,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                onPressed: onCollapse,
              ),
            ],
          ),
          // Progress through the whole surah, ayah by ayah (audio files are
          // per ayah, so a time bar would only cover one ayah).
          if (current != null && total > 1) ...[
            Slider(
              value: s.index.toDouble(),
              min: 0,
              max: (total - 1).toDouble(),
              divisions: total - 1,
              label: toArabicDigits(current.number),
              onChanged: (_) {},
              onChangeEnd: (v) => p.jumpTo(v.round()),
            ),
          ],
          if (current != null)
            Text(
              s.loading
                  ? AppStrings.audioLoading
                  : AppStrings.ayahProgress(
                      toArabicDigits(current.number),
                      toArabicDigits(total),
                    ),
              style: muted,
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SpeedButton(speed: s.speed, onSelected: p.setSpeed),
              IconButton(
                tooltip: AppStrings.previousAyah,
                iconSize: 30,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: s.hasPrevious ? p.previous : null,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                ),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: s.loading
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : IconButton(
                          iconSize: 36,
                          tooltip: s.playing ? AppStrings.pause : AppStrings.play,
                          icon: Icon(
                            s.error != null
                                ? Icons.refresh_rounded
                                : s.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          onPressed: p.toggle,
                        ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.nextAyah,
                iconSize: 30,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: s.hasNext ? p.next : null,
              ),
              IconButton(
                tooltip: AppStrings.stop,
                iconSize: 30,
                icon: const Icon(Icons.stop_rounded),
                onPressed: current == null ? null : p.stop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onSelected});
  final double speed;
  final void Function(double) onSelected;

  String _label(double v) => '${v}x'.replaceAll('.0x', 'x');

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: AppStrings.speed,
      initialValue: speed,
      color: AppColors.bg2Dark,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final v in AppConstants.playbackSpeeds)
          PopupMenuItem<double>(
            value: v,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: v == speed ? Icon(Icons.check, size: 18, color: AppColors.accent2) : null,
                ),
                Text(_label(v)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, size: 16, color: AppColors.accent2),
            const SizedBox(width: 4),
            Text(
              _label(speed),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
