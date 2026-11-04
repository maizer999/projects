class AppSettings {
  const AppSettings({
    required this.reciterId,
    required this.themePresetId,
    required this.ornateFrame,
    required this.tajweed,
    required this.mushafFontSize,
  });

  final String reciterId;
  final String themePresetId;
  final bool ornateFrame;
  final bool tajweed;

  /// Upper bound for the page's computed font size.
  final double mushafFontSize;

  AppSettings copyWith({
    String? reciterId,
    String? themePresetId,
    bool? ornateFrame,
    bool? tajweed,
    double? mushafFontSize,
  }) =>
      AppSettings(
        reciterId: reciterId ?? this.reciterId,
        themePresetId: themePresetId ?? this.themePresetId,
        ornateFrame: ornateFrame ?? this.ornateFrame,
        tajweed: tajweed ?? this.tajweed,
        mushafFontSize: mushafFontSize ?? this.mushafFontSize,
      );
}
