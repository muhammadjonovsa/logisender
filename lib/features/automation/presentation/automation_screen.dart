import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/widgets/animated_button.dart';
import 'package:logisender/core/widgets/glass_card.dart';
import 'package:logisender/core/widgets/gradient_background.dart';
import 'package:logisender/core/widgets/safe_text.dart';
import 'package:logisender/core/widgets/status_indicator.dart';
import 'package:logisender/features/automation/presentation/automation_provider.dart';
import 'package:logisender/features/templates/domain/smart_template_engine.dart';
import 'package:logisender/features/templates/presentation/templates_provider.dart';

/// Automation settings and control screen.
class AutomationScreen extends ConsumerWidget {
  const AutomationScreen({super.key});

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes daqiqa (tanaffus)';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours soat (tanaffus)';
    return '$hours soat $minutes daqiqa (tanaffus)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoState = ref.watch(automationProvider);
    final breakDuration = ref.watch(breakDurationProvider);
    final isRunning = autoState.isRunning;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.automation),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status hero
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRunning
                      ? const [
                          Color(0xFF10B981),
                          Color(0xFF0E1920),
                          Color(0xFF0E1118),
                        ]
                      : const [
                          Color(0xFF4A5FE0),
                          Color(0xFF131724),
                          Color(0xFF0E1118),
                        ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: (isRunning ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.35),
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusIndicator(
                        status: isRunning
                            ? IndicatorStatus.success
                            : IndicatorStatus.idle,
                        label: isRunning ? AppStrings.running : AppStrings.stopped,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isRunning
                                  ? AppColors.success
                                  : AppColors.textTertiary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRunning
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isRunning
                                  ? AppStrings.active
                                  : AppStrings.inactive,
                              style: TextStyle(
                                color: isRunning
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (autoState.currentGroup != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${AppStrings.sendingTo} ${autoState.currentGroup}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: autoState.totalGroups != null &&
                                autoState.totalGroups! > 0
                            ? ((autoState.currentGroupIndex ?? 0) + 1) /
                                autoState.totalGroups!
                            : null,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.1),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatMini(
                    icon: Icons.send_rounded,
                    value: '${autoState.totalSent}',
                    label: AppStrings.sent,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatMini(
                    icon: Icons.error_outline,
                    value: '${autoState.totalErrors}',
                    label: AppStrings.errors,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatMini(
                    icon: Icons.warning_amber_rounded,
                    value: autoState.hasFloodWait
                        ? '${autoState.floodWaitSeconds}s'
                        : '0',
                    label: AppStrings.floodWait,
                    color: autoState.hasFloodWait
                        ? AppColors.warning
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Round info
            GlassCard(
              useBlur: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.loop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Davra: ${autoState.roundCount}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (autoState.currentGroup != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${autoState.currentGroup} (${(autoState.currentGroupIndex ?? 0) + 1}/${autoState.totalGroups ?? 0})',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (autoState.lastAction != null)
              GlassCard(
                useBlur: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SafeText(
                        autoState.lastAction!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            GlassCard(
              useBlur: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.scheduleConfig,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: AppStrings.sendInterval,
                    value: _formatDuration(breakDuration),
                  ),
                  const SizedBox(height: 4),
                  const _InfoRow(
                    icon: Icons.shuffle_rounded,
                    label: AppStrings.groupSwitch,
                    value: AppStrings.groupSwitchValue,
                  ),
                  const SizedBox(height: 4),
                  const _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: AppStrings.intervalRefresh,
                    value: AppStrings.intervalRefreshValue,
                  ),
                  const SizedBox(height: 4),
                  const _InfoRow(
                    icon: Icons.speed_rounded,
                    label: AppStrings.sequencing,
                    value: AppStrings.sequencingValue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (isRunning)
              AnimatedButton(
                label: AppStrings.stopAutomation,
                icon: Icons.stop_rounded,
                gradientColors: const [Color(0xFFF04438), Color(0xFFF97066)],
                onPressed: () =>
                    ref.read(automationProvider.notifier).stopAutomation(),
              )
            else
              AnimatedButton(
                label: AppStrings.startAutomation,
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  final templateState = ref.read(templatesProvider);
                  final templates = templateState.templates;

                  if (templates.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.createTemplateFirst),
                      ),
                    );
                    return;
                  }

                  // Use the selected template, or the first one if none selected
                  final selectedTemplate =
                      templateState.selectedTemplate ?? templates.first;

                  ref.read(automationProvider.notifier).startAutomation(
                        textGenerator: () {
                          if (selectedTemplate.isSmart) {
                            return SmartTemplateEngine.generateVariation(
                                selectedTemplate.text);
                          }
                          return selectedTemplate.text;
                        },
                      );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatMini({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}