import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// On web desktop/tablet widths, centers the app in a phone-sized column so
/// mobile layouts don't stretch across a huge window. On real phones (and
/// on mobile builds) the child renders unchanged.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.maxPhoneWidth = 430,
    this.backdrop = const Color(0xFF1C2228),
  });

  final Widget child;
  final double maxPhoneWidth;
  final Color backdrop;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxPhoneWidth) return child;
        return ColoredBox(
          color: backdrop,
          child: Center(
            child: SizedBox(
              width: maxPhoneWidth,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
