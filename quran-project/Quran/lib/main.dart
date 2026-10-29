import 'package:flutter/material.dart';
import 'services/prefs.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await Prefs.create();
  final state = AppState(prefs);
  state.loadSurahs();
  runApp(QuranApp(state: state));
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        title: 'Al-Quran',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: false),
        darkTheme: buildTheme(dark: true),
        themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: HomeScreen(state: state),
      ),
    );
  }
}
