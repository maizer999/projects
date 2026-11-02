import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state/app_state.dart';
import 'quran_api.dart';

class PlayerController {
  PlayerController(this.state) {
    _player.onPlayerComplete.listen((_) => _onComplete());
    _player.onDurationChanged.listen((d) {
      duration = d;
      _emit();
    });
    _player.onPositionChanged.listen((p) {
      position = p;
      _emit();
    });
    _player.onPlayerStateChanged.listen((s) {
      _isPlaying = s == PlayerState.playing;
      state.setPlaybackState(
        ayahIdx: state.currentAyahIdx,
        playing: _isPlaying,
      );
      _emit();
    });
  }

  final AppState state;
  final AudioPlayer _player = AudioPlayer();

  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool _isPlaying = false;
  double speed = 1.0;

  static const List<double> speedSteps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  Future<void> setSpeed(double rate) async {
    speed = rate;
    await _player.setPlaybackRate(rate);
    _emit();
  }

  Future<void> cycleSpeed() async {
    final i = speedSteps.indexOf(speed);
    final next = speedSteps[(i + 1) % speedSteps.length];
    await setSpeed(next);
  }

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  void _emit() => _changes.add(null);

  Future<void> play(int idx) async {
    final sd = state.arabic;
    if (sd == null || idx < 0 || idx >= sd.ayahs.length) return;
    final a = sd.ayahs[idx];
    final url = QuranApi.ayahAudioUrl(state.reciterId, a.number);
    state.setPlaybackState(ayahIdx: idx, playing: true);
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      await _player.setPlaybackRate(speed);
    } catch (e) {
      debugPrint('PlayerController.play error: $e');
      state.setPlaybackState(ayahIdx: idx, playing: false);
    }
  }

  Future<void> toggle() async {
    final sd = state.arabic;
    if (sd == null) return;
    if (state.currentAyahIdx < 0) {
      await play(0);
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> next() async {
    final sd = state.arabic;
    if (sd == null) return;
    final n = state.currentAyahIdx + 1;
    if (n < sd.ayahs.length) await play(n);
  }

  Future<void> previous() async {
    if (state.currentAyahIdx > 0) {
      await play(state.currentAyahIdx - 1);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state.setPlaybackState(ayahIdx: -1, playing: false);
    position = Duration.zero;
    _emit();
  }

  Future<void> seek(Duration d) => _player.seek(d);

  void _onComplete() {
    final sd = state.arabic;
    final n = state.currentAyahIdx + 1;
    if (sd != null && n < sd.ayahs.length) {
      play(n);
    } else {
      state.setPlaybackState(ayahIdx: -1, playing: false);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _changes.close();
  }
}
