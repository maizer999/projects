import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/repositories/audio_repository.dart';
import 'dependency_providers.dart';
import 'reader_provider.dart';
import 'settings_provider.dart';

class PlayerState {
  const PlayerState({
    this.queue = const [],
    this.index = -1,
    this.playing = false,
    this.loading = false,
    this.error,
    this.speed = AppConstants.defaultPlaybackSpeed,
  });

  /// Ayahs of the surah being recited, in order.
  final List<Ayah> queue;
  final int index;
  final bool playing;

  /// Downloading/buffering the current ayah — shown to the user.
  final bool loading;

  /// User-facing message when the current ayah couldn't be played.
  final String? error;
  final double speed;

  Ayah? get current => (index >= 0 && index < queue.length) ? queue[index] : null;
  bool get hasNext => index >= 0 && index < queue.length - 1;
  bool get hasPrevious => index > 0;

  PlayerState copyWith({
    List<Ayah>? queue,
    int? index,
    bool? playing,
    bool? loading,
    String? error,
    bool clearError = false,
    double? speed,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        speed: speed ?? this.speed,
      );
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

/// The ayah being recited.
final playingAyahProvider = Provider<Ayah?>(
  (ref) => ref.watch(playerProvider.select((s) => s.current)),
);

class PlayerNotifier extends Notifier<PlayerState> {
  late AudioRepository _audio;

  /// Bumped on every play request so a slow, older request that finishes
  /// late can't overwrite the state of a newer one (fast taps).
  int _request = 0;

  @override
  PlayerState build() {
    _audio = ref.watch(audioRepositoryProvider);
    final sub = _audio.status.listen(_onStatus);
    ref.onDispose(sub.cancel);
    return const PlayerState();
  }

  void _onStatus(AudioStatus status) {
    switch (status) {
      case AudioStatus.playing:
        state = state.copyWith(playing: true, loading: false, clearError: true);
      case AudioStatus.paused:
      case AudioStatus.idle:
        if (!state.loading) state = state.copyWith(playing: false);
      case AudioStatus.completed:
        if (state.hasNext) {
          _playIndex(state.index + 1);
        } else {
          state = state.copyWith(index: -1, playing: false, loading: false);
        }
    }
  }

  Future<void> _playIndex(int index) async {
    final request = ++_request;
    final ayah = state.queue[index];
    state = state.copyWith(index: index, playing: false, loading: true, clearError: true);
    try {
      await _audio
          .playAyah(
            reciter: ref.read(currentReciterProvider),
            ayahId: ayah.id,
            speed: state.speed,
          )
          .timeout(AppConstants.audioLoadTimeout);
    } catch (e) {
      debugPrint('PlayerNotifier.play error: $e');
      if (request != _request) return; // a newer request took over
      await _audio.stop();
      state = state.copyWith(playing: false, loading: false, error: AppStrings.audioError);
    }
  }

  /// Recite [ayah]'s surah starting from [ayah].
  Future<void> playFrom(Ayah ayah) async {
    final queue = ref.read(getSurahAyahsProvider)(ayah.surah);
    final index = queue.indexWhere((a) => a.id == ayah.id);
    if (index < 0) return;
    state = state.copyWith(queue: queue);
    await _playIndex(index);
  }

  /// Play/pause. With nothing loaded, starts the reader's surah from the
  /// first of its ayahs on the visible page.
  Future<void> toggle() async {
    if (state.current == null) {
      final reader = ref.read(readerProvider);
      final ayahs = ref.read(getSurahAyahsProvider)(reader.surahNumber);
      if (ayahs.isEmpty) return;
      final start = ayahs.firstWhere((a) => a.page == reader.page, orElse: () => ayahs.first);
      await playFrom(start);
      return;
    }
    if (state.error != null || state.loading) {
      await retry();
      return;
    }
    if (state.playing) {
      await _audio.pause();
    } else {
      await _audio.resume();
    }
  }

  /// Try the current ayah again (after a network error).
  Future<void> retry() async {
    if (state.current != null) await _playIndex(state.index);
  }

  /// Jump to the [index]-th ayah of the surah being recited.
  Future<void> jumpTo(int index) async {
    if (index >= 0 && index < state.queue.length) await _playIndex(index);
  }

  Future<void> next() async {
    if (state.hasNext) await _playIndex(state.index + 1);
  }

  Future<void> previous() async {
    if (state.hasPrevious) await _playIndex(state.index - 1);
  }

  Future<void> stop() async {
    _request++;
    await _audio.stop();
    state = state.copyWith(index: -1, playing: false, loading: false, clearError: true);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _audio.setSpeed(speed);
  }
}
