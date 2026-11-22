import '../entities/app_settings.dart';
import '../entities/reciter.dart';
import '../repositories/settings_repository.dart';

class LoadSettings {
  const LoadSettings(this._repo);
  final SettingsRepository _repo;
  AppSettings call() => _repo.load();
}

class SaveSettings {
  const SaveSettings(this._repo);
  final SettingsRepository _repo;
  Future<void> call(AppSettings settings) => _repo.save(settings);
}

class GetReciters {
  const GetReciters(this._repo);
  final SettingsRepository _repo;
  List<Reciter> call() => _repo.getReciters();
}

class LoadReadingPosition {
  const LoadReadingPosition(this._repo);
  final SettingsRepository _repo;
  ({int page, int? surah}) call() =>
      (page: _repo.loadLastPage(), surah: _repo.loadLastSurah());
}

class SaveReadingPosition {
  const SaveReadingPosition(this._repo);
  final SettingsRepository _repo;

  Future<void> call({required int page, int? surah}) async {
    await _repo.saveLastPage(page);
    if (surah != null) await _repo.saveLastSurah(surah);
  }
}
