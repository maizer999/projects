import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_toolbar.dart';
import '../widgets/juz_list_panel.dart';
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
        const Expanded(child: SurahReader()),
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
