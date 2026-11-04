class AppSettings {
  const AppSettings({
    required this.reciterId,
    required this.themePresetId,
    required this.ornateFrame,
    required this.tajweed,
    required this.mushafFontSize,
    required this.fontId,
    required this.readingMode,
  });

  final String reciterId;
  final String themePresetId;
  final bool ornateFrame;
  final bool tajweed;

  /// Upper bound for the page's computed font size.
  final double mushafFontSize;

  /// Id of the Arabic font used for the text (see font_constants.dart).
  final String fontId;

  /// 'flow' (surah text, font choice applies) or 'pages' (Madinah pages, zoomable).
  final String readingMode;

  AppSettings copyWith({
    String? reciterId,
    String? themePresetId,
    bool? ornateFrame,
    bool? tajweed,
    double? mushafFontSize,
    String? fontId,
    String? readingMode,
  }) =>
      AppSettings(
        reciterId: reciterId ?? this.reciterId,
        themePresetId: themePresetId ?? this.themePresetId,
        ornateFrame: ornateFrame ?? this.ornateFrame,
        tajweed: tajweed ?? this.tajweed,
        mushafFontSize: mushafFontSize ?? this.mushafFontSize,
        fontId: fontId ?? this.fontId,
        readingMode: readingMode ?? this.readingMode,
      );
}
