import 'package:flutter/material.dart';
import '../models/juz.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// The app's primary navigation: 30 Juz, each expanding to the Surahs
/// inside it. Each Surah row has exactly two actions — Listen and
/// Memorize — plus that Surah's running mistake counter.
class SurahListPanel extends StatefulWidget {
  const SurahListPanel({
    super.key,
    required this.state,
    required this.onListen,
    required this.onMemorize,
  });

  final AppState state;
  final void Function(int surahNumber) onListen;
  final void Function(int surahNumber) onMemorize;

  @override
  State<SurahListPanel> createState() => _SurahListPanelState();
}

class _SurahListPanelState extends State<SurahListPanel> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _expandedJuz;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          _search(),
          const SizedBox(height: 8),
          Expanded(child: _list(context)),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          _Logo(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Al-Quran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  'القرآن الكريم · الأجزاء الثلاثون',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'ابحث عن جزء أو سورة...',
          prefixIcon: Icon(Icons.search, size: 18),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final s = widget.state;
    if (s.loadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.listError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعذّر التحميل. تحقق من الاتصال.',
                style: TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => s.loadSurahs(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    if (s.surahs.isEmpty) {
      return const SizedBox.shrink();
    }

    // When searching, flatten to matching surahs across all juz instead of
    // forcing the user to open each juz one by one.
    if (_query.isNotEmpty) {
      final matches = s.surahs.where((surah) {
        return surah.englishName.toLowerCase().contains(_query) ||
            surah.name.contains(_query) ||
            surah.number.toString() == _query;
      }).toList();
      if (matches.isEmpty) {
        return const Center(child: Text('لا توجد نتائج.'));
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) => _surahTile(matches[i]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: quranJuzs.length,
      itemBuilder: (context, i) => _juzTile(quranJuzs[i]),
    );
  }

  Widget _juzTile(Juz juz) {
    final s = widget.state;
    final dark = s.darkMode;
    final surahsInJuz = s.surahsInJuz(juz.number);
    final expanded = _expandedJuz == juz.number;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.panelDark : AppColors.panelLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: Colors.transparent,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
          key: PageStorageKey('juz_${juz.number}'),
          initiallyExpanded: expanded,
          onExpansionChanged: (open) {
            setState(() => _expandedJuz = open ? juz.number : null);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: dark ? AppColors.bg2Dark : AppColors.bg2Light,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: dark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${juz.number}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          title: Text(
            'الجزء ${_toArabicDigits(juz.number)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: surahsInJuz.isEmpty
              ? null
              : Text(
                  surahsInJuz.map((s) => s.englishName).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedDark),
                ),
          children: [
            if (surahsInJuz.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('...', style: TextStyle(color: AppColors.mutedDark)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  children: [
                    for (final surah in surahsInJuz) ...[
                      _surahTile(surah),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _surahTile(Surah surah) {
    final s = widget.state;
    final dark = s.darkMode;
    final selected = s.arabic != null && s.arabic!.number == surah.number;
    final mistakeCount = s.mistakeCountForSurah(surah.number);

    final bg = selected
        ? AppColors.accent.withValues(alpha: 0.14)
        : (dark ? AppColors.bg2Dark : AppColors.bg2Light);
    final border = selected
        ? AppColors.accent
        : (dark ? AppColors.borderDark : AppColors.borderLight);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: dark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${surah.number}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.name,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  surah.englishName,
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (mistakeCount > 0) _mistakeBadge(mistakeCount),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'استماع',
            icon: const Icon(Icons.headphones_outlined, size: 20),
            onPressed: () => widget.onListen(surah.number),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'حفظ',
            icon: const Icon(Icons.menu_book_outlined, size: 20),
            onPressed: () => widget.onMemorize(surah.number),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _mistakeBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Text(
        _toArabicDigits(count),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.danger,
        ),
      ),
    );
  }

  String _toArabicDigits(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accent2],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 10),
        ],
      ),
      child: const Center(
        child: Text(
          'ق',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
