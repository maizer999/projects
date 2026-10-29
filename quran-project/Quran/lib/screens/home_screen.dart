import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../services/player_controller.dart';
import '../widgets/surah_list_panel.dart';
import '../widgets/reader_view.dart';
import '../widgets/player_bar.dart';
import '../widgets/toolbar.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PlayerController _player;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _player = PlayerController(widget.state);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 900;
    final s = widget.state;

    final listPanel = SurahListPanel(
      state: s,
      onPick: (surahNumber) {
        s.loadSurah(surahNumber);
        if (!wide) Navigator.of(context).maybePop();
      },
    );

    final mainArea = Column(
      children: [
        AppToolbar(
          state: s,
          onOpenDrawer: wide ? null : () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: ReaderView(state: s, player: _player),
        ),
        if (s.arabic != null) PlayerBar(state: s, player: _player),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              width: 320,
              backgroundColor: s.darkMode ? AppColors.bg2Dark : AppColors.panelLight,
              child: SafeArea(child: listPanel),
            ),
      body: SafeArea(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 340, child: listPanel),
                  const VerticalDivider(width: 1),
                  Expanded(child: mainArea),
                ],
              )
            : mainArea,
      ),
    );
  }
}
