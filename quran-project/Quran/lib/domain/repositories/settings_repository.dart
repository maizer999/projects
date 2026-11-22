import '../entities/app_settings.dart';
import '../entities/reciter.dart';

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);

  List<Reciter> getReciters();

  int loadLastPage();
  Future<void> saveLastPage(int page);
  int? loadLastSurah();
  Future<void> saveLastSurah(int surah);
}
