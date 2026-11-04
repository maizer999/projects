import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../core/constants/api_constants.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/audio_player_data_source.dart';

class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl(this._player) {
    _subs = [
      _player.onStateChanged.listen((s) => _status.add(_map(s))),
      _player.onComplete.listen((_) => _status.add(AudioStatus.completed)),
    ];
  }

  final AudioPlayerDataSource _player;
  final _status = StreamController<AudioStatus>.broadcast();
  late final List<StreamSubscription<Object?>> _subs;

  static String ayahUrl(String reciterId, int ayahId) =>
      '${ApiConstants.audioCdnBase}/${ApiConstants.audioBitrate}/$reciterId/$ayahId.${ApiConstants.audioExtension}';

  AudioStatus _map(PlayerState s) => switch (s) {
        PlayerState.playing => AudioStatus.playing,
        PlayerState.paused => AudioStatus.paused,
        // Completion is reported separately through onComplete.
        PlayerState.completed => AudioStatus.paused,
        _ => AudioStatus.idle,
      };

  @override
  Stream<AudioStatus> get status => _status.stream;

  @override
  Stream<Duration> get position => _player.onPosition;

  @override
  Stream<Duration> get duration => _player.onDuration;

  @override
  Future<void> playAyah({
    required String reciterId,
    required int ayahId,
    required double speed,
  }) async {
    await _player.playUrl(ayahUrl(reciterId, ayahId));
    await _player.setRate(speed);
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setRate(speed);

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _status.close();
    await _player.dispose();
  }
}
