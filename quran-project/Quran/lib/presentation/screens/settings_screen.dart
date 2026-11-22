import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/font_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import 'contact_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static TextStyle get _label =>
      TextStyle(fontSize: 12, color: AppColors.mutedDark);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final reciters = ref.watch(recitersProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bg2Dark,
          title: const Text(AppStrings.settingsTitle),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Contact / Support ────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.support_agent,
                  color: AppColors.mutedDark, size: 22),
              title: const Text(AppStrings.contactUs,
                  style: TextStyle(fontSize: 14)),
              trailing: Icon(Icons.chevron_left_rounded,
                  color: AppColors.mutedDark),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ContactScreen(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Reciter ──────────────────────────────────────
            _SectionHeader(label: AppStrings.reciter),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: s.reciterId,
              items: [
                for (final r in reciters)
                  DropdownMenuItem(value: r.id, child: Text(r.name)),
              ],
              onChanged: (v) {
                if (v != null) notifier.setReciter(v);
              },
            ),

            const SizedBox(height: 24),

            // ── Font size ─────────────────────────────────────
            _SectionHeader(label: AppStrings.fontSize),
            const SizedBox(height: 10),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

            const SizedBox(height: 24),

            // ── Font type ─────────────────────────────────────
            _SectionHeader(label: AppStrings.arabicFont),
            const SizedBox(height: 8),
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

            const SizedBox(height: 24),

            // ── Theme color ───────────────────────────────────
            _SectionHeader(label: AppStrings.appColor),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final p in themePresets)
                  _Swatch(
                    preset: p,
                    selected: s.themePresetId == p.id,
                    onTap: () => notifier.setThemePreset(p.id),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Display toggles ───────────────────────────────
            _SectionHeader(label: 'العرض'),
            _ToggleTile(
              title: AppStrings.tajweed,
              subtitle: AppStrings.tajweedSubtitle,
              value: s.tajweed,
              onChanged: notifier.setTajweed,
            ),
            _ToggleTile(
              title: AppStrings.ornateFrame,
              subtitle: AppStrings.ornateFrameSubtitle,
              value: s.ornateFrame,
              onChanged: notifier.setOrnateFrame,
            ),

            const SizedBox(height: 24),

            _SectionHeader(label: 'التذكيرات'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_rounded,
                  color: AppColors.mutedDark, size: 22),
              title: const Text('تذكير القرآن',
                  style: TextStyle(fontSize: 14)),
              subtitle: Text(
                s.notificationsEnabled ? '✓ مفعّل' : 'متوقف',
                style: TextStyle(
                  fontSize: 12,
                  color: s.notificationsEnabled
                      ? AppColors.accent2
                      : AppColors.mutedDark,
                ),
              ),
              trailing: Icon(Icons.chevron_left_rounded,
                  color: AppColors.mutedDark),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedDark,
          letterSpacing: 0.5,
        ),
      );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData? icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: icon != null
            ? Icon(icon, color: AppColors.mutedDark, size: 22)
            : null,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
        ),
        value: value,
        activeColor: AppColors.accent2,
        onChanged: onChanged,
      );
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
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.accent2 : AppColors.mutedDark,
          ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [preset.accent, preset.accent2]),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(preset.label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}
