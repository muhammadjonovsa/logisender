import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/widgets/gradient_background.dart';
import 'package:logisender/core/widgets/safe_text.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/features/groups/presentation/groups_provider.dart';
import 'package:logisender/features/groups/presentation/widgets/group_tile.dart';

/// Modern groups selection screen optimized for large lists (200+).
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _initialized = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized || !mounted) return;
      _initialized = true;
      ref.read(groupsProvider.notifier).loadGroups();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.selectGroups),
          actions: const [_SelectedCountBadge()],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.searchGroups,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(groupsProvider.notifier).search('');
                          },
                        ),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    ref.read(groupsProvider.notifier).search(value);
                  });
                  setState(() {});
                },
              ),
            ),

            // Selection controls
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SelectionControlsRow(),
            ),

            const SizedBox(height: 8),

            // Groups list
            const Expanded(
              child: _GroupsListBuilder(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCountBadge extends ConsumerWidget {
  const _SelectedCountBadge();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(groupsProvider.select((s) => s.selectedCount));
    if (selectedCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppColors.softShadow(AppColors.primary, 0.35),
          ),
          child: SafeText(
            '$selectedCount ✅',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionControlsRow extends ConsumerWidget {
  const _SelectionControlsRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupCount = ref.watch(groupsProvider.select((s) => s.groupCount));
    final selectedCount = ref.watch(groupsProvider.select((s) => s.selectedCount));
    final areAllSelected = ref.watch(groupsProvider.select((s) => s.areAllVisibleSelected));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          SafeText(
            '$groupCount',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const SafeText(
            AppStrings.groups,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          SafeText(
            '$selectedCount',
            style: const TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const SafeText(
            AppStrings.groupsSelected,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (areAllSelected) {
                ref.read(groupsProvider.notifier).clearAll();
              } else {
                ref.read(groupsProvider.notifier).selectAll();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: areAllSelected
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    areAllSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    color: areAllSelected ? AppColors.error : AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  SafeText(
                    areAllSelected ? AppStrings.clearAll : AppStrings.selectAll,
                    style: TextStyle(
                      color: areAllSelected ? AppColors.error : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupsListBuilder extends ConsumerWidget {
  const _GroupsListBuilder();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(groupsProvider.select((s) => s.isLoading));
    final filteredGroups = ref.watch(groupsProvider.select((s) => s.filteredGroups));
    final searchQuery = ref.watch(groupsProvider.select((s) => s.searchQuery));
    final error = ref.watch(groupsProvider.select((s) => s.error));

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              SafeText(
                error,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ref.read(groupsProvider.notifier).retry(),
                icon: const Icon(Icons.refresh_rounded),
                label: const SafeText(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.groups_rounded,
                color: AppColors.textTertiary,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            SafeText(
              searchQuery.isNotEmpty ? AppStrings.noGroupsFound : AppStrings.failedToLoadGroups,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return _GroupTileWrapper(group: group);
      },
    );
  }
}

class _GroupTileWrapper extends ConsumerWidget {
  final TelegramGroup group;
  const _GroupTileWrapper({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch selection state for THIS specific group
    final isSelected = ref.watch(groupsProvider.select((s) => s.selectedIds.contains(group.id)));

    return GroupTile(
      group: group,
      isSelected: isSelected,
      onToggle: () {
        ref.read(groupsProvider.notifier).toggleSelection(group.id);
      },
    );
  }
}