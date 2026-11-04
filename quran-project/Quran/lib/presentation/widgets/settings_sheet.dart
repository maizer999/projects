import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/font_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg2Dark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const SettingsSheet(),
  );
}

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static TextStyle get _label => TextStyle(fontSize: 12, color: AppColors.mutedDark);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final reciters = ref.watch(recitersProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  AppStrings.settingsTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.reciter, style: _label),
              DropdownButtonFormField<String>(
                initialValue: s.reciterId,
                items: [
                  for (final r in reciters) DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) {
                  if (v != null) notifier.setReciter(v);
                },
              ),
              const SizedBox(height: 16),
              Text(AppStrings.fontSize, style: _label),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.add,
                    enabled: s.mushafFontSize < AppConstants.mushafFontMax,
                    onTap: () => notifier.bumpFontSize(AppConstants.mushafFontStep),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${s.mushafFontSize.round()}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.remove,
                    enabled: s.mushafFontSize > AppConstants.mushafFontMin,
                    onTap: () => notifier.bumpFontSize(-AppConstants.mushafFontStep),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(AppStrings.arabicFont, style: _label),
              DropdownButtonFormField<String>(
                initialValue: s.fontId,
                items: [
                  for (final f in arabicFonts)
                    DropdownMenuItem(value: f.id, child: Text(f.label)),
                ],
                onChanged: (v) {
                  if (v != null) notifier.setFont(v);
                },
              ),
              const SizedBox(height: 20),
              Text(AppStrings.appColor, style: _label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  for (final p in themePresets)
                    _Swatch(
                      preset: p,
                      selected: s.themePresetId == p.id,
                      onTap: () => notifier.setThemePreset(p.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDark),
            color: enabled ? AppColors.accent.withValues(alpha: 0.10) : null,
          ),
          child: Icon(icon, size: 20, color: enabled ? AppColors.accent2 : AppColors.mutedDark),
        ),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.preset, required this.selected, required this.onTap});
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [preset.accent, preset.accent2]),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
            ),
            const SizedBox(height: 4),
            Text(preset.label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
}
