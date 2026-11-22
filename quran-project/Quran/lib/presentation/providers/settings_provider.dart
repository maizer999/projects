import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushaf_text/mushaf_text.dart' as mt;

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/reciter.dart';
import 'dependency_providers.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final s = ref.watch(loadSettingsProvider)();
    AppColors.applyPreset(presetById(s.themePresetId));
    return s;
  }

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(saveSettingsProvider)(next);
  }

  Future<void> setReciter(String id) => _update(state.copyWith(reciterId: id));

  Future<void> setThemePreset(String id) {
    AppColors.applyPreset(presetById(id));
    return _update(state.copyWith(themePresetId: id));
  }

  Future<void> setOrnateFrame(bool value) => _update(state.copyWith(ornateFrame: value));

  Future<void> setTajweed(bool value) => _update(state.copyWith(tajweed: value));

  Future<void> setFont(String id) => _update(state.copyWith(fontId: id));

  Future<void> bumpFontSize(double delta) => _update(state.copyWith(
        mushafFontSize: (state.mushafFontSize + delta)
            .clamp(AppConstants.mushafFontMin, AppConstants.mushafFontMax),
      ));

  Future<void> setNotifications(bool enabled, List<mt.Ayah> ayahs) async {
    await _update(state.copyWith(notificationsEnabled: enabled));
    if (enabled) {
      await NotificationService.init();
      await NotificationService.requestPermission();
      await NotificationService.schedule(
        ayahs,
        fromId: state.notifFromAyah,
        toId: state.notifToAyah,
      );
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> setNotifRange({
    required int fromId,
    required int toId,
    required List<mt.Ayah> ayahs,
  }) async {
    await _update(state.copyWith(notifFromAyah: fromId, notifToAyah: toId));
    if (state.notificationsEnabled) {
      await NotificationService.schedule(ayahs, fromId: fromId, toId: toId);
    }
  }
}

final recitersProvider = Provider<List<Reciter>>((ref) => ref.watch(getRecitersProvider)());

final currentReciterProvider = Provider<Reciter>((ref) {
  final id = ref.watch(settingsProvider.select((s) => s.reciterId));
  final all = ref.watch(recitersProvider);
  return all.firstWhere((r) => r.id == id, orElse: () => all.first);
});
