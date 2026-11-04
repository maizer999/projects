const List<String> _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// 123 → ١٢٣
String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((c) {
      final d = int.tryParse(c);
      return d == null ? c : _arabicDigits[d];
    })
    .join();
