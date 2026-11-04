import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/font_constants.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_toolbar.dart';
import '../widgets/juz_list_panel.dart';
import '../providers/settings_provider.dart';
import '../widgets/mushaf_reader.dart';
import '../widgets/surah_reader.dart';
import '../widgets/player_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppConstants.wideLayoutBreakpoint;

    final main = Column(
      children: [
        AppToolbar(
          onOpenDrawer: wide ? null : () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(child: _ReaderArea()),
        const PlayerBar(),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              width: AppConstants.drawerWidth,
              backgroundColor: AppColors.bg2Dark,
              child: SafeArea(
                child: JuzListPanel(onSurahOpened: () => Navigator.of(context).maybePop()),
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: AppConstants.sidePanelWidth, child: JuzListPanel()),
                  const VerticalDivider(width: 1),
                  Expanded(child: main),
                ],
              )
            : main,
      ),
    );
  }
}

/// Chooses the reading view from settings: flowing surah text or pages.
class _ReaderArea extends ConsumerWidget {
  const _ReaderArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(settingsProvider.select((s) => s.readingMode)) == kReadingPages;
    return pages ? const MushafReader() : const SurahReader();
  }
}
