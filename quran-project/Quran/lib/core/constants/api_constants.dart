/// Remote endpoints used by the app.
///
/// The Quran text itself is bundled offline (package `mushaf_text`), so the
/// only network dependency left is the ayah-by-ayah recitation audio.
class ApiConstants {
  ApiConstants._();

  /// Islamic Network audio CDN (the same audio alquran.cloud serves).
  /// Full URL: `$audioCdnBase/$audioBitrate/{reciterId}/{globalAyahId}.mp3`
  static const String audioCdnBase = 'https://cdn.islamic.network/quran/audio';

  /// Bitrate folder on the CDN (kbps).
  static const String audioBitrate = '128';

  /// File extension of the audio files.
  static const String audioExtension = 'mp3';

  /// WhatsApp click-to-chat base used by the Contact screen.
  static const String whatsappBase = 'https://wa.me';
}
