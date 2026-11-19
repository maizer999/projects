/// Normalize an Arabic string for duplicate detection and search:
/// - strip tashkeel
/// - fold أ/إ/آ → ا
/// - fold ى → ي
/// - fold ة → ه
/// - fold ؤ → و, ئ → ي
/// - collapse whitespace, trim, lowercase ASCII
String normalizeAr(String input) {
  final sb = StringBuffer();
  for (final rune in input.runes) {
    // Skip tashkeel (combining marks U+064B..U+0652, U+0670)
    if ((rune >= 0x064B && rune <= 0x0652) || rune == 0x0670) continue;
    // Skip tatweel
    if (rune == 0x0640) continue;
    switch (rune) {
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0622: // آ
      case 0x0671: // ٱ
        sb.writeCharCode(0x0627); // ا
        break;
      case 0x0649: // ى
        sb.writeCharCode(0x064A); // ي
        break;
      case 0x0629: // ة
        sb.writeCharCode(0x0647); // ه
        break;
      case 0x0624: // ؤ
        sb.writeCharCode(0x0648); // و
        break;
      case 0x0626: // ئ
        sb.writeCharCode(0x064A); // ي
        break;
      default:
        sb.writeCharCode(rune);
    }
  }
  return sb
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Convert Arabic-Indic (٠١٢٣٤٥٦٧٨٩) and Persian (۰۱۲۳۴۵۶۷۸۹) digits
/// to ASCII, and the Arabic decimal/thousands separators (٫ ،) to `.` so
/// `double.tryParse` works regardless of keyboard layout.
String toAsciiDigits(String input) {
  final sb = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      sb.writeCharCode(0x0030 + (rune - 0x0660));
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      sb.writeCharCode(0x0030 + (rune - 0x06F0));
    } else if (rune == 0x066B || rune == 0x060C) {
      sb.writeCharCode(0x002E); // ٫ ، → .
    } else {
      sb.writeCharCode(rune);
    }
  }
  return sb.toString();
}

/// Parse a number that may contain Arabic digits.
double? parseFlexibleDouble(String input) {
  return double.tryParse(toAsciiDigits(input).trim());
}
