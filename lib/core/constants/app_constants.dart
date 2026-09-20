/// Application-wide constants for LogiSender Pro.
abstract final class AppConstants {
  static const String appName = 'LogiSender Pro';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String groupsBox = 'groups';
  static const String selectedGroupsBox = 'selected_groups';
  static const String templatesBox = 'templates';
  static const String statisticsBox = 'statistics';
  static const String automationBox = 'automation';
  static const String automationStateBox = 'automation_state';
  static const String logsBox = 'logs';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String breakDurationKey = 'break_duration_minutes';

  // Secure storage keys
  static const String apiKeyKey = 'api_id';
  static const String apiHashKey = 'api_hash';
  static const String sessionKey = 'session_data';
  static const String phoneKey = 'phone_number';
  static const String userIdKey = 'user_id';
  static const String automationRunningKey = 'automation_running';

  // Automation defaults (adjusted for 3-5s per group and 70 min round break)
  static const int minSendIntervalSeconds = 4200; // 70 minutes
  static const int maxSendIntervalSeconds = 4200;
  static const int groupSwitchMinSeconds = 1;
  static const int groupSwitchMaxSeconds = 3;
  static const int maxRetries = 3;
  static const int defaultFloodWaitBufferSeconds = 60;

  // Log limits
  static const int maxLogEntries = 500;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Regex
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
  static final RegExp codeRegex = RegExp(r'^\d{5,6}$');
  static final RegExp apiIdRegex = RegExp(r'^\d{1,10}$');
  static final RegExp apiHashRegex = RegExp(r'^[a-fA-F0-9]{32}$');
}
