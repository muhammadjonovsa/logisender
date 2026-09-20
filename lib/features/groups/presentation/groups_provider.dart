import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/features/groups/data/groups_repository.dart';

/// State for the groups selection feature.
class GroupsState {
  final List<TelegramGroup> allGroups;
  final List<TelegramGroup> filteredGroups;
  final Set<int> selectedIds;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const GroupsState({
    this.allGroups = const [],
    this.filteredGroups = const [],
    this.selectedIds = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  bool get areAllVisibleSelected =>
      filteredGroups.isNotEmpty &&
      filteredGroups.every((g) => selectedIds.contains(g.id));

  int get groupCount => allGroups.length;
  int get selectedCount => selectedIds.length;

  GroupsState copyWith({
    List<TelegramGroup>? allGroups,
    List<TelegramGroup>? filteredGroups,
    Set<int>? selectedIds,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      allGroups: allGroups ?? this.allGroups,
      filteredGroups: filteredGroups ?? this.filteredGroups,
      selectedIds: selectedIds ?? this.selectedIds,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GroupsNotifier extends StateNotifier<GroupsState> {
  final GroupsRepository _repository;

  GroupsNotifier(this._repository) : super(const GroupsState());

  /// Load cached groups from local Hive storage instantly (no network).
  /// Used by the Home screen so the app starts without blocking on Telegram.
  Future<void> loadCachedGroups() async {
    final groups = await _repository.loadCachedGroups();
    if (!mounted) return;
    state = GroupsState(
      allGroups: groups,
      filteredGroups: groups,
      selectedIds: _repository.selectedIds,
    );
  }

  /// Load all groups from Telegram.
  Future<void> loadGroups() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final groups = await _repository.loadAllGroups().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          final cached = _repository.allGroups;
          return cached.isNotEmpty ? cached : <TelegramGroup>[];
        },
      );

      if (!mounted) return;

      if (groups.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Guruhlar topilmadi. Internetni tekshiring va qayta urinib ko\'ring.');
        return;
      }

      final prevQuery = state.searchQuery;
      state = GroupsState(
        allGroups: groups,
        filteredGroups: prevQuery.isEmpty ? groups : _repository.filterGroups(prevQuery),
        selectedIds: _repository.selectedIds,
        searchQuery: prevQuery,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: 'Guruhlarni yuklashda xatolik: ${e.toString()}');
    }
  }

  /// Retry loading groups after an error.
  Future<void> retry() async {
    await loadGroups();
  }

  /// Search groups locally (instant, no network).
  void search(String query) {
    final filtered = _repository.filterGroups(query);
    state = state.copyWith(
      searchQuery: query,
      filteredGroups: filtered,
    );
  }

  /// Toggle selection of a single group.
  Future<void> toggleSelection(int groupId) async {
    await _repository.toggleSelection(groupId);
    state = state.copyWith(
      selectedIds: Set.from(_repository.selectedIds),
    );
  }

  /// Select all currently visible (filtered) groups.
  Future<void> selectAll() async {
    await _repository.selectAll(state.filteredGroups);
    state = state.copyWith(
      selectedIds: Set.from(_repository.selectedIds),
    );
  }

  /// Clear all selections.
  Future<void> clearAll() async {
    await _repository.clearAll();
    state = state.copyWith(selectedIds: {});
  }

  /// Toggle favorite on a group.
  Future<void> toggleFavorite(int groupId) async {
    await _repository.toggleFavorite(groupId);
    if (!mounted) return;
    // Refresh the list from repository
    final groups = _repository.allGroups;
    final filtered = _repository.filterGroups(state.searchQuery);
    state = state.copyWith(
      allGroups: List.from(groups),
      filteredGroups: filtered,
    );
  }

  /// Toggle enabled on a group.
  Future<void> toggleEnabled(int groupId) async {
    await _repository.toggleEnabled(groupId);
    if (!mounted) return;
    final groups = _repository.allGroups;
    final filtered = _repository.filterGroups(state.searchQuery);
    state = state.copyWith(
      allGroups: List.from(groups),
      filteredGroups: filtered,
    );
  }
}

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  return GroupsNotifier(ref.watch(groupsRepositoryProvider));
});
