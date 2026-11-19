import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/repository.dart';
import 'data/theme_settings.dart';
import 'ui/glass.dart';
import 'ui/landing_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedId = await ThemeSettings.get();
  BaytiColors.applyPreset(presetById(savedId));
  runApp(BaytiApp(initialPresetId: savedId));
}

abstract class BaytiAppController {
  String get presetId;
  Future<void> setPreset(String id);
}

class BaytiApp extends StatefulWidget {
  const BaytiApp({super.key, required this.initialPresetId});
  final String initialPresetId;

  static BaytiAppController of(BuildContext context) =>
      context.findAncestorStateOfType<_BaytiAppState>()!;

  @override
  State<BaytiApp> createState() => _BaytiAppState();
}

class _BaytiAppState extends State<BaytiApp> implements BaytiAppController {
  late String _presetId = widget.initialPresetId;

  @override
  String get presetId => _presetId;

  @override
  Future<void> setPreset(String id) async {
    if (id == _presetId) return;
    BaytiColors.applyPreset(presetById(id));
    await ThemeSettings.set(id);
    if (!mounted) return;
    setState(() => _presetId = id);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ListRepository();
    return MaterialApp(
      title: 'بيتي',
      debugShowCheckedModeBanner: false,
      theme: buildBaytiTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: GlassBackground(child: child ?? const SizedBox()),
      ),
      home: LandingScreen(repo: repo),
    );
  }
}
