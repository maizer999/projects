import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PageImage extends StatelessWidget {
  const PageImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.loading,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final Widget? loading;
  final Widget Function(Object error)? error;

  bool get _isSvg => url.toLowerCase().contains('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.network(
        url,
        fit: fit,
        placeholderBuilder: (_) =>
            loading ?? const Center(child: CircularProgressIndicator()),
      );
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, prog) => prog == null
          ? child
          : (loading ?? const Center(child: CircularProgressIndicator())),
      errorBuilder: (_, e, __) =>
          error?.call(e) ?? const Center(child: Icon(Icons.broken_image)),
    );
  }
}
