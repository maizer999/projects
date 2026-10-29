import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SurahListPanel extends StatefulWidget {
  const SurahListPanel({super.key, required this.state, required this.onPick});
  final AppState state;
  final void Function(int surahNumber) onPick;

  @override
  State<SurahListPanel> createState() => _SurahListPanelState();
}

class _SurahListPanelState extends State<SurahListPanel> {
  final _searchCtrl = TextEditingController();

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
          _header(context),
          _search(),
          _filters(),
          const SizedBox(height: 8),
          Expanded(child: _list(context)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Al-Quran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  'القرآن الكريم · The Noble Quran',
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
        onChanged: widget.state.setSearch,
        decoration: const InputDecoration(
          hintText: 'Search surah...',
          prefixIcon: Icon(Icons.search, size: 18),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _chip('All', SurahFilter.all),
          _chip('Meccan', SurahFilter.meccan),
          _chip('Medinan', SurahFilter.medinan),
          _chip('Bookmarks', SurahFilter.bookmarks),
        ],
      ),
    );
  }

  Widget _chip(String label, SurahFilter f) {
    final active = widget.state.filter == f;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: active,
      onSelected: (_) => widget.state.setFilter(f),
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(color: active ? Colors.white : null),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
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
                'Failed to load. Check connection.',
                style: TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => s.loadSurahs(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final items = s.filteredSurahs;
    if (items.isEmpty) {
      return const Center(child: Text('No surahs match.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) => _tile(context, items[i]),
    );
  }

  Widget _tile(BuildContext context, Surah s) {
    final selected =
        widget.state.arabic != null && widget.state.arabic!.number == s.number;
    final dark = widget.state.darkMode;
    final bg = selected
        ? AppColors.accent.withValues(alpha: 0.18)
        : (dark ? AppColors.panelDark : AppColors.panelLight);
    final border = selected
        ? AppColors.accent
        : (dark ? AppColors.borderDark : AppColors.borderLight);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onPick(s.number),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: dark ? AppColors.bg2Dark : AppColors.bg2Light,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${s.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.englishName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${s.englishNameTranslation} · ${s.numberOfAyahs} verses · ${s.revelationType}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.name,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
