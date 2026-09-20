import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/router/route_names.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/utils/date_utils.dart' as app;
import 'package:logisender/core/widgets/animated_button.dart';
import 'package:logisender/core/widgets/app_logo.dart';
import 'package:logisender/core/widgets/glass_card.dart';
import 'package:logisender/core/widgets/gradient_background.dart';
import 'package:logisender/core/widgets/safe_text.dart';
import 'package:logisender/core/widgets/section_header.dart';
import 'package:logisender/core/widgets/status_indicator.dart';
import 'package:logisender/features/automation/presentation/automation_provider.dart';
import 'package:logisender/features/groups/presentation/groups_provider.dart';
import 'package:logisender/features/home/presentation/home_provider.dart';
import 'package:logisender/features/home/presentation/widgets/dashboard_card.dart';
import 'package:logisender/features/templates/presentation/templates_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized || !mounted) return;
      _initialized = true;
      ref.read(homeProvider.notifier).loadData();
      ref.read(templatesProvider.notifier).loadTemplates();
      // Load groups from local cache only — full Telegram load happens on the Groups tab
      ref.read(groupsProvider.notifier).loadCachedGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(homeProvider.select((s) => s.userName));

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(homeProvider.notifier).refresh();
              await ref.read(groupsProvider.notifier).loadGroups();
              await ref.read(templatesProvider.notifier).loadTemplates();
            },
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.hello}, ${userName ?? AppStrings.user}!',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              AppStrings.dashboard,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const AppLogo(size: 52),
                    ],
                  ),
                ),

                const _StatusCard(),

                const SizedBox(height: 14),

                const _StatsRow(),

                const SizedBox(height: 14),

                const _GroupsAndFloodRow(),

                const SizedBox(height: 24),

                _SectionHeader(
                  title: AppStrings.selectedGroupsPreview,
                  actionText: AppStrings.viewAll,
                  onTap: () => context.go(RouteNames.groups),
                ),
                const SizedBox(height: 10),

                const _RecentGroupsList(),

                const SizedBox(height: 24),

                _SectionHeader(
                  title: AppStrings.templatesPreview,
                  actionText: AppStrings.viewAll,
                  onTap: () => context.go(RouteNames.templates),
                ),
                const SizedBox(height: 10),

                const _RecentTemplatesList(),

                const SizedBox(height: 20),

                const _AutomationButton(),

                const SizedBox(height: 12),

                const _AutomationSettingsLink(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automation = ref.watch(automationProvider);
    final homeState = ref.watch(homeProvider);
    final isRunning = automation.isRunning;

    return Container(
      decoration: BoxDecoration(
        gradient: isRunning
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF0B1220)],
                stops: [0.0, 0.55],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF242B3A), Color(0xFF10141D)],
                stops: [0.0, 0.6],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isRunning
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.borderSoft,
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isRunning ? AppColors.success : AppColors.textTertiary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.AppDateUtils.formatTime(DateTime.now()),
                    style: TextStyle(
                      color: isRunning
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (homeState.lastSentTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.lastSent}: ${app.AppDateUtils.relativeTime(homeState.lastSentTime!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySent = ref.watch(homeProvider.select((s) => s.todaySent));
    final todayErrors = ref.watch(homeProvider.select((s) => s.todayErrors));
    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            icon: Icons.send_rounded,
            label: AppStrings.sentToday,
            value: '$todaySent',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DashboardCard(
            icon: Icons.error_outline,
            label: AppStrings.errors,
            value: '$todayErrors',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _GroupsAndFloodRow extends ConsumerWidget {
  const _GroupsAndFloodRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(groupsProvider.select((s) => s.selectedCount));
    final hasFloodWait = ref.watch(homeProvider.select((s) => s.hasFloodWait));
    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            icon: Icons.groups_rounded,
            label: AppStrings.groups,
            value: '$selectedCount',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DashboardCard(
            icon: Icons.warning_amber_rounded,
            label: AppStrings.floodWait,
            value: hasFloodWait ? AppStrings.active : AppStrings.none,
            color: hasFloodWait ? AppColors.warning : AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _AutomationButton extends ConsumerWidget {
  const _AutomationButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automation = ref.watch(automationProvider);
    return AnimatedButton(
      label: automation.isRunning
          ? AppStrings.stopAutomation
          : AppStrings.startAutomation,
      icon: automation.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
      height: 58,
      gradientColors: automation.isRunning
          ? const [Color(0xFFF04438), Color(0xFFF97066)]
          : null,
      onPressed: () {
        if (automation.isRunning) {
          ref.read(automationProvider.notifier).stopAutomation();
        } else {
          context.go(RouteNames.automation);
        }
      },
    );
  }
}

class _AutomationSettingsLink extends StatelessWidget {
  const _AutomationSettingsLink();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBlur: false,
      onTap: () => context.go(RouteNames.automation),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Row(
        children: [
          Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.automationSettings,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _RecentGroupsList extends ConsumerWidget {
  const _RecentGroupsList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(groupsProvider.select((s) => s.isLoading));
    final selectedIds = ref.watch(groupsProvider.select((s) => s.selectedIds));
    final allGroups = ref.watch(groupsProvider.select((s) => s.allGroups));

    if (isLoading) {
      return const _PreviewLoadingCard();
    }

    final selectedGroups = allGroups.where((g) => selectedIds.contains(g.id)).take(3).toList();

    if (selectedGroups.isEmpty) {
      return const GlassCard(
        useBlur: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              AppStrings.noSelectedGroups,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final group in selectedGroups)
          GlassCard(
            useBlur: false,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: SafeText(
                      group.title.isNotEmpty ? group.title[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SafeText(
                    group.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.memberCount > 0 ? '${_formatCount(group.memberCount)} 👥' : '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _RecentTemplatesList extends ConsumerWidget {
  const _RecentTemplatesList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesState = ref.watch(templatesProvider);

    if (templatesState.isLoading) {
      return const _PreviewLoadingCard();
    }

    if (templatesState.templates.isEmpty) {
      return const GlassCard(
        useBlur: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(AppStrings.noTemplatesYet, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final template in templatesState.templates.take(3))
          GlassCard(
            useBlur: false,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: template.isSmart ? AppColors.successGradient : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    template.isSmart ? Icons.auto_awesome_rounded : Icons.article_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SafeText(
                        template.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      SafeText(
                        template.text,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PreviewLoadingCard extends StatelessWidget {
  const _PreviewLoadingCard();
  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      useBlur: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title, actionText: actionText, onTap: onTap);
  }
}