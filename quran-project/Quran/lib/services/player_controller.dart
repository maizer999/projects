import 'dart:async';
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
    } catch (_) {
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
