import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/widgets/gradient_background.dart';
import 'package:logisender/features/statistics/presentation/statistics_provider.dart';
import 'package:logisender/features/statistics/presentation/widgets/stat_card.dart';
import 'package:logisender/features/statistics/presentation/widgets/log_tile.dart';

/// Statistics and real-time logs screen.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_loaded || !mounted) return;
      _loaded = true;
      ref.read(statisticsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statisticsProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  AppStrings.statisticsLogs,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              _PeriodSelector(
                values: StatsPeriod.values,
                selected: statsState.selectedPeriod,
                onChanged: (p) =>
                    ref.read(statisticsProvider.notifier).setPeriod(p),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: DashStatCard(
                      icon: Icons.send_rounded,
                      label: AppStrings.totalSent,
                      value: '${statsState.summary.totalSent}',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashStatCard(
                      icon: Icons.check_circle_outline,
                      label: AppStrings.successful,
                      value: '${statsState.summary.successfulSends}',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DashStatCard(
                      icon: Icons.error_outline,
                      label: AppStrings.errors,
                      value: '${statsState.summary.totalErrors}',
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashStatCard(
                      icon: Icons.speed,
                      label: AppStrings.successRate,
                      value: '${statsState.summary.successRate.toStringAsFixed(1)}%',
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                AppStrings.recentLogs,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              if (statsState.logs.isEmpty)
                _EmptyLogsCard()
              else
                ...statsState.logs.take(20).map(
                      (log) => LogTile(log: log),
                    ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final List<StatsPeriod> values;
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  const _PeriodSelector({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient:
                      isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? AppColors.softShadow(AppColors.primary, 0.3)
                      : null,
                ),
                child: Text(
                  _periodLabel(period),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _periodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.today:
        return AppStrings.today;
      case StatsPeriod.yesterday:
        return AppStrings.yesterday;
      case StatsPeriod.week:
        return AppStrings.week;
      case StatsPeriod.month:
        return AppStrings.month;
    }
  }
}

class _EmptyLogsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 28,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.logsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}