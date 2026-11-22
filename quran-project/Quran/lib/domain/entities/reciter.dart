class Reciter {
  const Reciter(this.id, this.name, this.bitrate);

  /// CDN folder id, e.g. `ar.alafasy`.
  final String id;
  final String name;

  /// CDN quality folder that actually holds this reciter's files (kbps).
  /// Not every reciter exists in every quality — asking for the wrong one
  /// returns 403 and the ayah stays silent.
  final int bitrate;
}
