import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logisender/core/theme/app_colors.dart';

/// Reusable glassmorphism card with soft blur, gradient, and subtle glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final bool hasBorder;
  final bool useBlur;
  final VoidCallback? onTap;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.opacity = 0.06,
    this.hasBorder = true,
    this.useBlur = true,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              )
            : null,
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );

    if (useBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: AppColors.primary.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color ?? AppColors.card.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(borderRadius),
                border: hasBorder
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      )
                    : null,
                boxShadow: AppColors.cardShadow,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return content;
  }
}