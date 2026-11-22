class AppSettings {
  const AppSettings({
    required this.reciterId,
    required this.themePresetId,
    required this.ornateFrame,
    required this.tajweed,
    required this.mushafFontSize,
    required this.fontId,
    this.notificationsEnabled = false,
    this.notifFromAyah = 1,
    this.notifToAyah = 6236,
  });

  final String reciterId;
  final String themePresetId;
  final bool ornateFrame;
  final bool tajweed;

  /// Upper bound for the page's computed font size.
  final double mushafFontSize;

  /// Id of the Arabic font used for the text (see font_constants.dart).
  final String fontId;

  final bool notificationsEnabled;
  final int notifFromAyah;
  final int notifToAyah;

  AppSettings copyWith({
    String? reciterId,
    String? themePresetId,
    bool? ornateFrame,
    bool? tajweed,
    double? mushafFontSize,
    String? fontId,
    bool? notificationsEnabled,
    int? notifFromAyah,
    int? notifToAyah,
  }) =>
      AppSettings(
        reciterId: reciterId ?? this.reciterId,
        themePresetId: themePresetId ?? this.themePresetId,
        ornateFrame: ornateFrame ?? this.ornateFrame,
        tajweed: tajweed ?? this.tajweed,
        mushafFontSize: mushafFontSize ?? this.mushafFontSize,
        fontId: fontId ?? this.fontId,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        notifFromAyah: notifFromAyah ?? this.notifFromAyah,
        notifToAyah: notifToAyah ?? this.notifToAyah,
      );
}
