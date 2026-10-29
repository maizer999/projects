import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../services/player_controller.dart';
import '../theme.dart';

Future<void> showAyahActions(
  BuildContext context, {
  required AppState state,
  required PlayerController player,
  required int ayahIdx,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: state.darkMode ? AppColors.bg2Dark : AppColors.panelLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final arabic = state.arabic!;
      final a = arabic.ayahs[ayahIdx];
      final bk = state.isBookmarked(arabic.number, a.numberInSurah);
      final mk = state.isMistake(arabic.number, a.numberInSurah);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'آية ${a.numberInSurah}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tile(
                  Icons.play_arrow,
                  'استمع',
                  () {
                    Navigator.pop(ctx);
                    player.play(ayahIdx);
                  },
                ),
                _tile(
                  mk ? Icons.cancel : Icons.cancel_outlined,
                  'خطأ',
                  () {
                    state.toggleMistake(arabic.number, a.numberInSurah);
                    Navigator.pop(ctx);
                  },
                  color: AppColors.danger,
                  active: mk,
                ),
                _tile(
                  bk ? Icons.bookmark : Icons.bookmark_border,
                  'حفظ',
                  () {
                    state.toggleBookmark(arabic.number, a.numberInSurah);
                    Navigator.pop(ctx);
                  },
                  color: AppColors.gold,
                  active: bk,
                ),
                _tile(
                  Icons.copy,
                  'نسخ',
                  () async {
                    final tr = state.translation?.ayahs[ayahIdx];
                    final text =
                        '${a.text}\n\n${tr != null ? "${tr.text}\n\n" : ""}— Surah ${arabic.englishName} (${arabic.number}:${a.numberInSurah})';
                    await Clipboard.setData(ClipboardData(text: text));
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _tile(
  IconData icon,
  String label,
  VoidCallback onTap, {
  Color? color,
  bool active = false,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? (color ?? AppColors.accent)
                  : (color ?? AppColors.accent).withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : (color ?? AppColors.accent),
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
