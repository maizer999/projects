import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';

class AppToolbar extends StatelessWidget {
  const AppToolbar({super.key, required this.state, this.onOpenDrawer});
  final AppState state;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: s.darkMode ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onOpenDrawer != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onOpenDrawer,
            ),
          Expanded(
            child: s.arabic == null
                ? Text(
                    'اختر من القائمة',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedDark),
                  )
                : Text(
                    s.arabic!.name,
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          if (s.arabic != null && s.mistakeCountForSurah(s.arabic!.number) > 0)
            TextButton.icon(
              onPressed: () => _confirmReset(
                context,
                s.arabic!.number,
                s.mistakeCountForSurah(s.arabic!.number),
              ),
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.danger),
              label: Text(
                'تصفير (${s.mistakeCountForSurah(s.arabic!.number)})',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    int surahNumber,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير الأخطاء؟'),
        content: Text('رح يتم حذف علامات الأخطاء الـ$count لهاي السورة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.resetSurahMistakeCount(surahNumber);
    }
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          state.darkMode ? AppColors.bg2Dark : AppColors.panelLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SettingsSheet(state: state),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'إعدادات القراءة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Text('القارئ', style: _lbl),
            DropdownButtonFormField<String>(
              initialValue: state.reciterId,
              items: AppState.reciters
                  .map((r) => DropdownMenuItem(
                        value: r.id,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(r.name, textDirection: TextDirection.rtl),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) state.setReciter(v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('حجم الخط', style: _lbl)),
                Text(state.arSize.round().toString()),
              ],
            ),
            const SizedBox(height: 8),
            _SizeStepper(state: state),
            const SizedBox(height: 20),
            Text('لون التطبيق', style: _lbl),
            const SizedBox(height: 8),
            _ColorPicker(state: state),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.ornateFrame,
              onChanged: state.setOrnateFrame,
              title: const Text(
                'إطار المصحف المزخرف',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                'إطار ذهبي مزخرف حول صفحة القراءة، أو تصميم بسيط ونظيف',
                style: _lbl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle get _lbl =>
      const TextStyle(fontSize: 12).copyWith(color: AppColors.mutedDark);
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final preset in themePresets) ...[
          _swatch(preset),
          const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _swatch(ThemePreset preset) {
    final selected = state.accentPresetId == preset.id;
    return GestureDetector(
      onTap: () => state.setAccentPreset(preset.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [preset.accent, preset.accent2],
              ),
              border: Border.all(
                color: selected
                    ? (state.darkMode ? Colors.white : Colors.black)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          Text(preset.label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

class _SizeStepper extends StatelessWidget {
  const _SizeStepper({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final canDec = state.arSize > AppState.arSizeMin;
    final canInc = state.arSize < AppState.arSizeMax;
    return Row(
      children: [
        _stepBtn(
          icon: Icons.remove,
          enabled: canDec,
          onTap: () => state.bumpArSize(-AppState.arSizeStep),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${state.arSize.round()} px',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        _stepBtn(
          icon: Icons.add,
          enabled: canInc,
          onTap: () => state.bumpArSize(AppState.arSizeStep),
        ),
      ],
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: state.darkMode
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
          color: enabled
              ? AppColors.accent.withValues(alpha: 0.10)
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.accent : AppColors.mutedDark,
        ),
      ),
    );
  }
}
