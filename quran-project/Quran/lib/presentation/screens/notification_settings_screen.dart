import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mushaf_text/mushaf_text.dart' as mt;

import '../../core/theme/app_colors.dart';
import '../providers/dependency_providers.dart';
import '../providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late bool _enabled;
  late int _fromSurah;
  late int _fromAyah;
  late int _toSurah;
  late int _toAyah;

  List<mt.Surah> get _surahs => mt.Quran.surahs;

  int _surahAyahCount(int surahNumber) =>
      _surahs.firstWhere((s) => s.number == surahNumber).ayahCount;

  // Convert surah+ayah → global ayah id
  int _toGlobalId(int surah, int ayah) {
    final allAyahs = ref.read(allMushafAyahsProvider);
    return allAyahs
        .firstWhere((a) => a.surah == surah && a.number == ayah,
            orElse: () => allAyahs.first)
        .id;
  }

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _enabled = s.notificationsEnabled;

    final allAyahs = ref.read(allMushafAyahsProvider);
    final fromAyah =
        allAyahs.firstWhere((a) => a.id == s.notifFromAyah, orElse: () => allAyahs.first);
    final toAyah =
        allAyahs.firstWhere((a) => a.id == s.notifToAyah, orElse: () => allAyahs.last);

    _fromSurah = fromAyah.surah;
    _fromAyah  = fromAyah.number;
    _toSurah   = toAyah.surah;
    _toAyah    = toAyah.number;
  }

  Future<void> _save() async {
    final fromId = _toGlobalId(_fromSurah, _fromAyah);
    final toId   = _toGlobalId(_toSurah, _toAyah);
    if (fromId > toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نقطة البداية يجب أن تكون قبل نقطة النهاية')),
      );
      return;
    }
    final notifier = ref.read(settingsProvider.notifier);
    final ayahs   = ref.read(allMushafAyahsProvider);
    await notifier.setNotifRange(fromId: fromId, toId: toId, ayahs: ayahs);
    await notifier.setNotifications(_enabled, ayahs);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bg2Dark,
          title: const Text('إعدادات التذكيرات'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _save,
              child: Text('حفظ',
                  style: TextStyle(color: AppColors.accent2, fontSize: 16)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Enable toggle ─────────────────────────────────
            _Card(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.notifications_rounded,
                    color: AppColors.accent2),
                title: const Text('تفعيل التذكيرات',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'إشعار كل ٣٠ دقيقة بآيات من المدى المحدد',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedDark),
                ),
                value: _enabled,
                activeColor: AppColors.accent2,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ),

            const SizedBox(height: 20),

            // ── From ──────────────────────────────────────────
            _SectionLabel(label: 'من (البداية)'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: [
                  _SurahPicker(
                    label: 'السورة',
                    value: _fromSurah,
                    surahs: _surahs,
                    onChanged: (v) => setState(() {
                      _fromSurah = v;
                      _fromAyah  = 1;
                    }),
                  ),
                  Divider(color: AppColors.borderDark, height: 1),
                  _AyahPicker(
                    label: 'الآية',
                    value: _fromAyah,
                    max: _surahAyahCount(_fromSurah),
                    onChanged: (v) => setState(() => _fromAyah = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── To ────────────────────────────────────────────
            _SectionLabel(label: 'إلى (النهاية)'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: [
                  _SurahPicker(
                    label: 'السورة',
                    value: _toSurah,
                    surahs: _surahs,
                    onChanged: (v) => setState(() {
                      _toSurah = v;
                      _toAyah  = _surahAyahCount(v);
                    }),
                  ),
                  Divider(color: AppColors.borderDark, height: 1),
                  _AyahPicker(
                    label: 'الآية',
                    value: _toAyah,
                    max: _surahAyahCount(_toSurah),
                    onChanged: (v) => setState(() => _toAyah = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Summary ───────────────────────────────────────
            _Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.mutedDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ستصلك إشعارات بآيات من '
                        '${_surahs.firstWhere((s) => s.number == _fromSurah).nameArabic} '
                        '(${_fromAyah}) '
                        'حتى '
                        '${_surahs.firstWhere((s) => s.number == _toSurah).nameArabic} '
                        '(${_toAyah})',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.mutedDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('حفظ الإعدادات'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent2,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedDark,
            letterSpacing: 0.5),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg2Dark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: child,
      );
}

class _SurahPicker extends StatelessWidget {
  const _SurahPicker({
    required this.label,
    required this.value,
    required this.surahs,
    required this.onChanged,
  });
  final String label;
  final int value;
  final List<mt.Surah> surahs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            isDense: true,
          ),
          value: value,
          isExpanded: true,
          items: [
            for (final s in surahs)
              DropdownMenuItem(
                value: s.number,
                child: Text('${s.number}. ${s.nameArabic}'),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}

class _AyahPicker extends StatelessWidget {
  const _AyahPicker({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            isDense: true,
          ),
          value: value.clamp(1, max),
          isExpanded: true,
          items: [
            for (int i = 1; i <= max; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}
