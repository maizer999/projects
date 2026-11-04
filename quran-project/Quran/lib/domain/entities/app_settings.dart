class AppSettings {
  const AppSettings({
    required this.reciterId,
    required this.themePresetId,
    required this.ornateFrame,
    required this.tajweed,
    required this.mushafFontSize,
    required this.fontId,
  });

  final String reciterId;
  final String themePresetId;
  final bool ornateFrame;
  final bool tajweed;

  /// Upper bound for the page's computed font size.
  final double mushafFontSize;

  /// Id of the Arabic font used for the text (see font_constants.dart).
  final String fontId;

  AppSettings copyWith({
    String? reciterId,
    String? themePresetId,
    bool? ornateFrame,
    bool? tajweed,
    double? mushafFontSize,
    String? fontId,
  }) =>
      AppSettings(
        reciterId: reciterId ?? this.reciterId,
        themePresetId: themePresetId ?? this.themePresetId,
        ornateFrame: ornateFrame ?? this.ornateFrame,
        tajweed: tajweed ?? this.tajweed,
        mushafFontSize: mushafFontSize ?? this.mushafFontSize,
        fontId: fontId ?? this.fontId,
      );
}
