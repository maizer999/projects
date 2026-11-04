import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
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
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = AppConstants.defaultPlaybackSpeed,
  });

  /// Ayahs of the surah being recited, in order.
  final List<Ayah> queue;
  final int index;
  final bool playing;
  final Duration position;
  final Duration duration;
  final double speed;

  Ayah? get current => (index >= 0 && index < queue.length) ? queue[index] : null;
  bool get hasNext => index >= 0 && index < queue.length - 1;
  bool get hasPrevious => index > 0;

  PlayerState copyWith({
    List<Ayah>? queue,
    int? index,
    bool? playing,
    Duration? position,
    Duration? duration,
    double? speed,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        speed: speed ?? this.speed,
      );
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

/// The ayah being recited — watch this instead of [playerProvider] when the
/// position ticks don't matter (they fire several times a second).
final playingAyahProvider = Provider<Ayah?>(
  (ref) => ref.watch(playerProvider.select((s) => s.current)),
);

class PlayerNotifier extends Notifier<PlayerState> {
  late AudioRepository _audio;

  @override
  PlayerState build() {
    _audio = ref.watch(audioRepositoryProvider);
    final subs = <StreamSubscription<Object?>>[
      _audio.status.listen(_onStatus),
      _audio.position.listen((p) => state = state.copyWith(position: p)),
      _audio.duration.listen((d) => state = state.copyWith(duration: d)),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });
    return const PlayerState();
  }

  void _onStatus(AudioStatus status) {
    switch (status) {
      case AudioStatus.playing:
        state = state.copyWith(playing: true);
      case AudioStatus.paused:
      case AudioStatus.idle:
        state = state.copyWith(playing: false);
      case AudioStatus.completed:
        if (state.hasNext) {
          _playIndex(state.index + 1);
        } else {
          state = state.copyWith(index: -1, playing: false, position: Duration.zero);
        }
    }
  }

  Future<void> _playIndex(int index) async {
    final ayah = state.queue[index];
    state = state.copyWith(index: index, playing: true, position: Duration.zero);
    try {
      await _audio.playAyah(
        reciterId: ref.read(settingsProvider).reciterId,
        ayahId: ayah.id,
        speed: state.speed,
      );
    } catch (e) {
      debugPrint('PlayerNotifier.play error: $e');
      state = state.copyWith(playing: false);
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
    if (state.playing) {
      await _audio.pause();
    } else {
      await _audio.resume();
    }
  }

  Future<void> next() async {
    if (state.hasNext) await _playIndex(state.index + 1);
  }

  Future<void> previous() async {
    if (state.hasPrevious) await _playIndex(state.index - 1);
  }

  Future<void> stop() async {
    await _audio.stop();
    state = state.copyWith(index: -1, playing: false, position: Duration.zero);
  }

  Future<void> seek(Duration position) => _audio.seek(position);

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _audio.setSpeed(speed);
  }
}
