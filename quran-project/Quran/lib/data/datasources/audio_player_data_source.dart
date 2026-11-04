import 'package:audioplayers/audioplayers.dart';

/// Wraps the `audioplayers` plugin.
class AudioPlayerDataSource {
  AudioPlayerDataSource([AudioPlayer? player]) : _player = player ?? AudioPlayer();
  final AudioPlayer _player;

  /// Call once before runApp so audio plays as media (background, ducking).
  static Future<void> configureGlobalContext() => AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );

  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;
  Stream<void> get onComplete => _player.onPlayerComplete;
  Stream<Duration> get onPosition => _player.onPositionChanged;
  Stream<Duration> get onDuration => _player.onDurationChanged;

  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration d) => _player.seek(d);
  Future<void> setRate(double rate) => _player.setPlaybackRate(rate);
  Future<void> dispose() => _player.dispose();
}
