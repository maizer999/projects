enum AudioStatus { idle, playing, paused, completed }

/// Plays one ayah's recitation at a time.
abstract interface class AudioRepository {
  Stream<AudioStatus> get status;
  Stream<Duration> get position;
  Stream<Duration> get duration;

  Future<void> playAyah({required String reciterId, required int ayahId, required double speed});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}
