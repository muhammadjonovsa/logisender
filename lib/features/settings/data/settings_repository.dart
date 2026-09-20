import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/storage/secure_storage_service.dart';

/// Repository for app settings operations.
class SettingsRepository {
  final SecureStorageService _secureStorage;
  final HiveStorageService _hiveStorage;

  SettingsRepository({
    required SecureStorageService secureStorage,
    required HiveStorageService hiveStorage,
  })  : _secureStorage = secureStorage,
        _hiveStorage = hiveStorage;

  Future<void> clearAllData() async {
    await _secureStorage.clearAll();
  }

  /// Sets the break duration between sending rounds in minutes.
  Future<void> setBreakDuration(int minutes) async {
    await _hiveStorage.put(AppConstants.settingsBox, AppConstants.breakDurationKey, minutes);
  }

  /// Gets the break duration between sending rounds in minutes.
  /// Defaults to 70 minutes if not set.
  Future<int> getBreakDuration() async {
    final dynamic value = await _hiveStorage.get(AppConstants.settingsBox, AppConstants.breakDurationKey);
    return value as int? ?? (AppConstants.minSendIntervalSeconds ~/ 60);
  }
}
