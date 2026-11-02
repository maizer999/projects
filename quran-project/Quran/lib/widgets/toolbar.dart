import 'package:flutter/material.dart';
import '../screens/surah_memorize_screen.dart';
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.arabic == null
                      ? 'اختر من القائمة'
                      : 'سورة ${s.arabic!.number} · ${s.arabic!.numberOfAyahs} آية',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (s.arabic != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                s.arabic!.name,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (s.arabic != null)
            IconButton(
              tooltip: 'وضع الحفظ',
              icon: const Icon(Icons.menu_book, color: AppColors.gold),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SurahMemorizeScreen(
                    state: s,
                    surahNumber: s.arabic!.number,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => _openSettings(context),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(s.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: s.toggleTheme,
          ),
        ],
      ),
    );
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
                'Reader settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Reciter', style: _lbl),
            DropdownButtonFormField<String>(
              initialValue: state.reciterId,
              items: AppState.reciters
                  .map((r) =>
                      DropdownMenuItem(value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) state.setReciter(v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Arabic size', style: _lbl)),
                Text(state.arSize.round().toString()),
              ],
            ),
            const SizedBox(height: 8),
            _SizeStepper(state: state),
          ],
        ),
      ),
    );
  }

  static const _lbl =
      TextStyle(fontSize: 12, color: AppColors.mutedDark);
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
