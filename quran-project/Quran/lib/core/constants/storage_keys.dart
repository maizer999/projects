/// SharedPreferences keys. Existing keys keep their old names so saved data
/// (reciter, theme, mistake marks) survives the upgrade.
class StorageKeys {
  StorageKeys._();

  static const String reciter = 'reciter';
  static const String themePreset = 'accentPreset';
  static const String ornateFrame = 'ornateFrame';
  static const String tajweed = 'tajweed';
  static const String mushafFontSize = 'mushafMaxFont';
  static const String arabicFont = 'arabicFont';
  static const String lastPage = 'lastPage';
  static const String lastSurah = 'lastSurah';

  /// JSON: `{ "surahNumber": [ayahNumberInSurah, ...] }`
  static const String surahMistakeAyahs = 'surahMistakeAyahs';

  /// JSON array of surah numbers the user marked as favourite.
  static const String favoriteSurahs = 'favoriteSurahs';
}
