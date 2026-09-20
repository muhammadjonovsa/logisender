import 'package:flutter/material.dart';
import 'package:logisender/core/theme/app_colors.dart';

/// Brand logo mark with gradient tile and optional glow.
class AppLogo extends StatelessWidget {
  final double size;
  final IconData icon;
  final bool glow;

  const AppLogo({
    super.key,
    this.size = 64,
    this.icon = Icons.send_rounded,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: size * 0.45,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}