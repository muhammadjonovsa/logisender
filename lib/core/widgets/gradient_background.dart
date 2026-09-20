import 'package:flutter/material.dart';
import 'package:logisender/core/theme/app_colors.dart';

/// Full-screen gradient background with soft ambient glows.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors ??
                const [
                  Color(0xFF0B1020),
                  Color(0xFF080B13),
                  Color(0xFF07090F),
                ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow blobs
            const Positioned(
              top: -120,
              right: -80,
              child: _GlowBlob(
                color: AppColors.primary,
                size: 320,
                opacity: 0.14,
              ),
            ),
            const Positioned(
              top: 160,
              left: -120,
              child: _GlowBlob(
                color: AppColors.brandViolet,
                size: 280,
                opacity: 0.1,
              ),
            ),
            const Positioned(
              bottom: -140,
              right: -60,
              child: _GlowBlob(
                color: AppColors.brandCyan,
                size: 340,
                opacity: 0.1,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}