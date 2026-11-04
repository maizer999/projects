/// App-wide fixed values. Change behaviour here, not inside widgets.
class AppConstants {
  AppConstants._();

  static const String appTitle = 'Al-Quran';

  // ---- Mushaf ----
  static const int firstPage = 1;
  static const int totalPages = 604;
  static const int totalJuz = 30;
  static const int totalSurahs = 114;

  // ---- Mushaf font size (ceiling passed to MushafPage.maxFontSize) ----
  static const double mushafFontMin = 20;
  static const double mushafFontMax = 68;
  static const double mushafFontStep = 2;
  static const double mushafFontDefault = 34;

  /// Pinch-zoom / font-button scale bounds (derived from the font range so
  /// the +/- buttons and gesture stay in sync).
  static const double mushafZoomMin = mushafFontMin / mushafFontDefault; // ≈0.59
  static const double mushafZoomMax = mushafFontMax / mushafFontDefault; // ≈2.0

  // ---- Audio ----
  static const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const double defaultPlaybackSpeed = 1.0;
  static const String defaultReciterId = 'ar.alafasy';

  // ---- Theme ----
  static const String defaultThemePresetId = 'green';

  // ---- Layout ----
  /// Width at which the surah list becomes a permanent side panel.
  static const double wideLayoutBreakpoint = 900;
  static const double sidePanelWidth = 340;
  static const double drawerWidth = 320;

  // ---- Animations ----
  static const Duration pageTurnDuration = Duration(milliseconds: 350);
  static const Duration playerToggleDuration = Duration(milliseconds: 220);
  static const Duration snackBarDuration = Duration(seconds: 2);
}
