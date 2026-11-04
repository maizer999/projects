import '../../core/constants/app_constants.dart';
import '../../core/constants/font_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/preferences_data_source.dart';
import '../datasources/reciters_data.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);
  final PreferencesDataSource _prefs;

  @override
  AppSettings load() => AppSettings(
        reciterId: _prefs.getString(StorageKeys.reciter) ?? AppConstants.defaultReciterId,
        themePresetId:
            _prefs.getString(StorageKeys.themePreset) ?? AppConstants.defaultThemePresetId,
        ornateFrame: _prefs.getBool(StorageKeys.ornateFrame) ?? true,
        tajweed: _prefs.getBool(StorageKeys.tajweed) ?? false,
        mushafFontSize:
            _prefs.getDouble(StorageKeys.mushafFontSize) ?? AppConstants.mushafFontDefault,
        fontId: _prefs.getString(StorageKeys.arabicFont) ?? kDefaultFontId,
        readingMode: _prefs.getString(StorageKeys.readingMode) ?? kReadingFlow,
      );

  @override
  Future<void> save(AppSettings s) async {
    await _prefs.setString(StorageKeys.reciter, s.reciterId);
    await _prefs.setString(StorageKeys.themePreset, s.themePresetId);
    await _prefs.setBool(StorageKeys.ornateFrame, s.ornateFrame);
    await _prefs.setBool(StorageKeys.tajweed, s.tajweed);
    await _prefs.setDouble(StorageKeys.mushafFontSize, s.mushafFontSize);
    await _prefs.setString(StorageKeys.arabicFont, s.fontId);
    await _prefs.setString(StorageKeys.readingMode, s.readingMode);
  }

  @override
  List<Reciter> getReciters() => recitersData;

  @override
  int loadLastPage() => _prefs.getInt(StorageKeys.lastPage) ?? AppConstants.firstPage;

  @override
  Future<void> saveLastPage(int page) => _prefs.setInt(StorageKeys.lastPage, page);

  @override
  int? loadLastSurah() {
    final v = _prefs.getInt(StorageKeys.lastSurah);
    return (v == null || v < 1) ? null : v;
  }

  @override
  Future<void> saveLastSurah(int surah) => _prefs.setInt(StorageKeys.lastSurah, surah);
}
