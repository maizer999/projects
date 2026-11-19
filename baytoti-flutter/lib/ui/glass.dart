import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Soft gradient background used behind every screen so glass surfaces
/// have something to refract. Teal → cream → amber mist.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                BaytiColors.primarySoft,
                const Color(0xFFF6F7FB),
                BaytiColors.accentSoft,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _blob(220, BaytiColors.primary, 0.28),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: _blob(260, BaytiColors.accent, 0.22),
        ),
        Positioned(
          top: 180,
          left: -40,
          child: _blob(180, BaytiColors.primaryDark, 0.14),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// A translucent frosted-glass surface with blur + specular highlight.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.tint,
    this.blur = 22,
    this.opacity = 0.55,
    this.border = true,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? tint;
  final double blur;
  final double opacity;
  final bool border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final baseTint = tint ?? Colors.white;
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  baseTint.withValues(alpha: opacity + 0.12),
                  baseTint.withValues(alpha: opacity),
                  baseTint.withValues(alpha: opacity - 0.08),
                ],
              ),
              border: border
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A floating glass bar — used for app bars and bottom nav.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 24,
    this.blur = 28,
    this.opacity = 0.6,
  });

  final Widget child;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: opacity + 0.15),
                Colors.white.withValues(alpha: opacity),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A chip-style pill with a glass look.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? BaytiColors.primary.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.55);
    final fg = selected ? Colors.white : BaytiColors.text;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A gradient highlight rim used around primary glass surfaces (hero card).
class GlassHero extends StatelessWidget {
  const GlassHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final grad = gradient ??
        LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [BaytiColors.primary, BaytiColors.primaryDark],
        );
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: grad,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
