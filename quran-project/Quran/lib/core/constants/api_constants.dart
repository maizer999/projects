/// Remote endpoints used by the app.
///
/// The Quran text itself is bundled offline (package `mushaf_text`), so the
/// only network dependency left is the ayah-by-ayah recitation audio.
class ApiConstants {
  ApiConstants._();

  /// Islamic Network audio CDN (the same audio alquran.cloud serves).
  /// Full URL: `$audioCdnBase/{reciter.bitrate}/{reciter.id}/{globalAyahId}.mp3`
  /// (each reciter exists only in some bitrates — see reciters_data.dart).
  static const String audioCdnBase = 'https://cdn.islamic.network/quran/audio';

  /// File extension of the audio files.
  static const String audioExtension = 'mp3';

  /// WhatsApp click-to-chat base used by the Contact screen.
  static const String whatsappBase = 'https://wa.me';
}
