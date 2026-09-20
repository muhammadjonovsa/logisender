import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/telegram/telegram_client.dart';
import 'package:logisender/core/telegram/telegram_models.dart';

/// Repository for loading all Telegram groups and managing selected groups.
class GroupsRepository {
  final TelegramClient _client;
  final HiveStorageService _hiveStorage;

  GroupsRepository({
    required TelegramClient client,
    required HiveStorageService hiveStorage,
  })  : _client = client,
        _hiveStorage = hiveStorage;

  List<TelegramGroup> _allGroups = [];
  Set<int> _selectedIds = {};

  List<TelegramGroup> get allGroups => List.unmodifiable(_allGroups);
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Loads cached groups and selection state from Hive without any network.
  ///
  /// Used on the Home screen so the app starts instantly instead of blocking
  /// the UI on a full Telegram dialogs download.
  Future<List<TelegramGroup>> loadCachedGroups() async {
    await _loadSelectedIds();
    try {
      final raw = await _hiveStorage.getAll(AppConstants.groupsBox);
      final groups = <TelegramGroup>[];
      final seen = <String>{};
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id'];
          if (id != null && seen.add(id.toString())) {
            groups.add(TelegramGroup.fromJson(map));
          }
        }
      }
      if (groups.isNotEmpty) {
        debugPrint('[GroupsRepo] loadCachedGroups loaded ${groups.length} groups');
        _allGroups = groups;
      }
    } catch (e) {
      debugPrint('[GroupsRepo] loadCachedGroups error (non-fatal): $e');
    }
    return _allGroups;
  }

  /// Load ALL groups from Telegram, then merge with Hive selection state.
  Future<List<TelegramGroup>> loadAllGroups() async {
    debugPrint('[GroupsRepo] loadAllGroups STARTED');
    final sw = Stopwatch()..start();

    await _loadSelectedIds();

    final Map<String, Map<String, dynamic>> savedState = {};
    try {
      final rawSaved = await _hiveStorage.getAll(AppConstants.groupsBox);
      for (final raw in rawSaved) {
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          final id = map['id'];
          if (id != null) savedState[id.toString()] = map;
        }
      }
    } catch (e) {
      debugPrint('[GroupsRepo] Hive read error (non-fatal): $e');
    }

    const maxRetries = 2;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (!_client.isConnected) {
          debugPrint('[GroupsRepo] Client not connected, attempting connect...');
          await _client.connect();
        }

        final groups = await _client.loadAllGroups().timeout(const Duration(seconds: 40));

        if (groups.isEmpty && _allGroups.isNotEmpty) {
          debugPrint('[GroupsRepo] loadAllGroups returned empty but we have ${_allGroups.length} cached groups, keeping cache');
          return _allGroups;
        }

        if (groups.isNotEmpty) {
          debugPrint('[GroupsRepo] loadAllGroups returned ${groups.length} groups (${sw.elapsedMilliseconds}ms)');
          // Run the merge in a background Isolate to avoid UI stutter for 1000+ groups
          _allGroups = await Isolate.run(() => _mergeGroupsWithSavedState(groups, savedState));
          // Persist the full list so the Home screen can render instantly next launch
          unawaited(_cacheAllGroups());
          // Compact Hive box to prevent file from growing indefinitely
          unawaited(_hiveStorage.compact(AppConstants.groupsBox));
        }

        debugPrint('[GroupsRepo] loadAllGroups FINISHED: ${_allGroups.length} groups, ${_selectedIds.length} selected');
        return _allGroups;
      } on TimeoutException catch (e) {
        debugPrint('[GroupsRepo] loadAllGroups TIMEOUT (attempt $attempt): $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        return _allGroups.isNotEmpty ? _allGroups : [];
      } catch (e, st) {
        debugPrint('[GroupsRepo] loadAllGroups FAILED (attempt $attempt): $e');
        debugPrint('[GroupsRepo] StackTrace: $st');
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        return _allGroups.isNotEmpty ? _allGroups : [];
      }
    }
    return _allGroups.isNotEmpty ? _allGroups : [];
  }

  /// Toggle a single group's selection.
  Future<void> toggleSelection(int groupId) async {
    if (_selectedIds.contains(groupId)) {
      _selectedIds.remove(groupId);
    } else {
      _selectedIds.add(groupId);
    }
    await _saveSelectedIds();
  }

  /// Select all visible groups (filtered by search).
  Future<void> selectAll(List<TelegramGroup> visibleGroups) async {
    final oldSize = _selectedIds.length;
    for (final g in visibleGroups) {
      _selectedIds.add(g.id);
    }
    if (_selectedIds.length != oldSize) {
      await _saveSelectedIds();
    }
  }

  /// Clear all selections.
  Future<void> clearAll() async {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    await _saveSelectedIds();
  }

  /// Toggle favorite.
  Future<void> toggleFavorite(int groupId) async {
    final index = _allGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;

    _allGroups[index] = _allGroups[index].copyWith(
      isFavorite: !_allGroups[index].isFavorite,
    );
    try {
      await _hiveStorage.put(AppConstants.groupsBox, groupId.toString(), _allGroups[index].toJson());
    } catch (e) {
      debugPrint('[GroupsRepo] Failed to save group state: $e');
    }
  }

  /// Toggle enabled (for automation).
  Future<void> toggleEnabled(int groupId) async {
    final index = _allGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;

    _allGroups[index] = _allGroups[index].copyWith(
      isEnabled: !_allGroups[index].isEnabled,
    );
    try {
      await _hiveStorage.put(AppConstants.groupsBox, groupId.toString(), _allGroups[index].toJson());
    } catch (e) {
      debugPrint('[GroupsRepo] Failed to save group state: $e');
    }
  }

  /// Get enabled groups for automation.
  List<TelegramGroup> getEnabledGroups() {
    return _allGroups.where((g) => g.isEnabled && _selectedIds.contains(g.id)).toList();
  }

  /// Get selected groups as TelegramGroup list.
  List<TelegramGroup> getSelectedGroups() {
    return _allGroups.where((g) => _selectedIds.contains(g.id)).toList();
  }

  /// Filter groups by search query (instant, no network).
  List<TelegramGroup> filterGroups(String query) {
    if (query.isEmpty) return _allGroups;
    final q = query.toLowerCase();
    return _allGroups.where((g) =>
      g.title.toLowerCase().contains(q) ||
      (g.username?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  // ── Hive persistence ──

  Future<void> _loadSelectedIds() async {
    try {
      final raw = await _hiveStorage.getAll(AppConstants.selectedGroupsBox);
      _selectedIds = raw
          .whereType<int>()
          .toSet();
      debugPrint('[GroupsRepo] Loaded ${_selectedIds.length} selected IDs from Hive');
    } catch (e) {
      debugPrint('[GroupsRepo] Failed to load selected IDs: $e');
      _selectedIds = {};
    }
  }

  Future<void> _saveSelectedIds() async {
    try {
      final entries = <String, dynamic>{};
      for (final id in _selectedIds) {
        entries[id.toString()] = id;
      }
      await _hiveStorage.clear(AppConstants.selectedGroupsBox);
      await _hiveStorage.putAll(AppConstants.selectedGroupsBox, entries);
    } catch (e) {
      debugPrint('[GroupsRepo] Failed to save selected IDs: $e');
    }
  }

  /// Saves the full merged group list to Hive for fast offline startup.
  Future<void> _cacheAllGroups() async {
    try {
      final entries = <String, dynamic>{};
      for (final g in _allGroups) {
        entries[g.id.toString()] = g.toJson();
      }
      await _hiveStorage.putAll(AppConstants.groupsBox, entries);
      debugPrint('[GroupsRepo] Cached ${entries.length} groups to Hive');
    } catch (e) {
      debugPrint('[GroupsRepo] Failed to cache groups: $e');
    }
  }
}

/// Top-level function required by Isolate.run (cannot be a closure or instance method).
/// Merges Telegram API groups with saved isFavorite/isEnabled state from Hive.
List<TelegramGroup> _mergeGroupsWithSavedState(
  List<TelegramGroup> groups,
  Map<String, Map<String, dynamic>> savedState,
) {
  return groups.map((g) {
    final saved = savedState[g.id.toString()];
    if (saved != null) {
      return g.copyWith(
        isFavorite: saved['isFavorite'] as bool? ?? false,
        isEnabled: saved['isEnabled'] as bool? ?? true,
      );
    }
    return g;
  }).toList();
}
