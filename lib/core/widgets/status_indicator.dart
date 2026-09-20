import 'package:flutter/material.dart';
import 'package:logisender/core/theme/app_colors.dart';

/// Animated status indicator dot — uses a single pulse on state change,
/// NOT a continuous loop, to avoid frame drops.
enum IndicatorStatus { success, error, warning, idle }

class StatusIndicator extends StatefulWidget {
  final IndicatorStatus status;
  final String? label;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.label,
    this.size = 10,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    if (widget.status == IndicatorStatus.success) {
      _animController.forward().then((_) => _animController.reverse());
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status &&
        widget.status == IndicatorStatus.success) {
      _animController.forward(from: 0).then((_) => _animController.reverse());
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.status) {
      case IndicatorStatus.success:
        return AppColors.success;
      case IndicatorStatus.error:
        return AppColors.error;
      case IndicatorStatus.warning:
        return AppColors.warning;
      case IndicatorStatus.idle:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _getColor(),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(width: 8),
          Text(
            widget.label!,
            style: TextStyle(
              color: _getColor(),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
