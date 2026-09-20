import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';

/// Persists automation state so that if the app is killed during a FloodWait
/// or a sending round, it can resume correctly on next launch.
class AutomationStateService {
  final HiveStorageService _hive;

  AutomationStateService({required HiveStorageService hive}) : _hive = hive;

  static const _floodWaitUntilKey = 'flood_wait_until';
  static const _floodWaitGroupKey = 'flood_wait_group';
  static const _roundKey = 'round_count';

  /// Save the FloodWait deadline so we can resume after an app restart.
  Future<void> saveFloodWait({
    required DateTime floodWaitUntil,
    required String groupName,
  }) async {
    await _hive.put(AppConstants.automationStateBox, _floodWaitUntilKey, floodWaitUntil.millisecondsSinceEpoch);
    await _hive.put(AppConstants.automationStateBox, _floodWaitGroupKey, groupName);
  }

  /// Returns remaining FloodWait seconds (0 if already expired).
  Future<int> remainingFloodWaitSeconds() async {
    final raw = await _hive.get(AppConstants.automationStateBox, _floodWaitUntilKey);
    if (raw is! int) return 0;
    final until = DateTime.fromMillisecondsSinceEpoch(raw);
    final remaining = until.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Name of the group that caused FloodWait.
  Future<String?> floodWaitGroup() async {
    final raw = await _hive.get(AppConstants.automationStateBox, _floodWaitGroupKey);
    return raw is String ? raw : null;
  }

  /// Clear FloodWait state after it expires.
  Future<void> clearFloodWait() async {
    await _hive.delete(AppConstants.automationStateBox, _floodWaitUntilKey);
    await _hive.delete(AppConstants.automationStateBox, _floodWaitGroupKey);
  }

  /// Persist the current round count so UI can restore state.
  Future<void> saveRound(int round) async {
    await _hive.put(AppConstants.automationStateBox, _roundKey, round);
  }

  Future<int> loadRound() async {
    final raw = await _hive.get(AppConstants.automationStateBox, _roundKey);
    return raw is int ? raw : 0;
  }

  Future<void> clearAll() async {
    await _hive.clear(AppConstants.automationStateBox);
  }
}
