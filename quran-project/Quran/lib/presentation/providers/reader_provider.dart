import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import 'dependency_providers.dart';

enum ReaderMode { listen, memorize }

class ReaderState {
  const ReaderState({required this.page, required this.surahNumber, required this.mode});

  /// 1..604
  final int page;

  /// The surah the user is working on (player, mistakes reset).
  final int surahNumber;
  final ReaderMode mode;

  ReaderState copyWith({int? page, int? surahNumber, ReaderMode? mode}) => ReaderState(
        page: page ?? this.page,
        surahNumber: surahNumber ?? this.surahNumber,
        mode: mode ?? this.mode,
      );
}

final readerProvider = NotifierProvider<ReaderNotifier, ReaderState>(ReaderNotifier.new);

class ReaderNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    final pos = ref.watch(loadReadingPositionProvider)();
    final page = pos.page.clamp(AppConstants.firstPage, AppConstants.totalPages);
    final quran = ref.watch(quranRepositoryProvider);
    final saved = pos.surah;
    final surah = (saved != null && _surahContainsPage(saved, page))
        ? saved
        : quran.getSurahAtPage(page).number;
    return ReaderState(page: page, surahNumber: surah, mode: ReaderMode.listen);
  }

  bool _surahContainsPage(int surah, int page) {
    final s = ref.read(quranRepositoryProvider).getSurah(surah);
    return page >= s.startPage && page <= s.endPage;
  }

  /// Called when the user swipes (or playback turns) to [page].
  void setPage(int page) {
    if (page == state.page) return;
    final surah = _surahContainsPage(state.surahNumber, page)
        ? state.surahNumber
        : ref.read(quranRepositoryProvider).getSurahAtPage(page).number;
    state = state.copyWith(page: page, surahNumber: surah);
    _persist();
  }

  void openSurah(int number) {
    final s = ref.read(quranRepositoryProvider).getSurah(number);
    state = state.copyWith(page: s.startPage, surahNumber: number);
    _persist();
  }

  void openPage(int page) => setPage(page);

  void setMode(ReaderMode mode) => state = state.copyWith(mode: mode);

  void _persist() => unawaited(
        ref.read(saveReadingPositionProvider)(page: state.page, surah: state.surahNumber),
      );
}
