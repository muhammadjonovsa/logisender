import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:uuid/uuid.dart';

/// Service for recording and querying send logs.
class SendLogService {
  final HiveStorageService _hiveStorage;
  final LoggerService _logger;
  static const _uuid = Uuid();

  SendLogService({
    required HiveStorageService hiveStorage,
    required LoggerService logger,
  })  : _hiveStorage = hiveStorage,
        _logger = logger;

  Future<void> logSend({
    required int chatId,
    required String chatName,
    required String templateId,
    String? messageText,
    required SentStatus status,
    String? errorMessage,
    int? floodWaitSeconds,
  }) async {
    final log = SendLog(
      id: _uuid.v4(),
      chatId: chatId,
      chatName: chatName,
      templateId: templateId,
      messageText: messageText,
      sentTime: DateTime.now(),
      status: status,
      errorMessage: errorMessage,
      floodWaitSeconds: floodWaitSeconds,
    );

    await _hiveStorage.put(
      AppConstants.logsBox,
      log.id,
      log.toJson(),
    );

    _logger.debug('Log recorded: ${log.status.name} to $chatName');
  }

  Future<List<SendLog>> loadLogs() async {
    try {
      final data = await _hiveStorage.getAll(AppConstants.logsBox);
      final logs = data
          .whereType<Map>()
          .map((e) => SendLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      logs.sort((a, b) => b.sentTime.compareTo(a.sentTime));

      if (logs.length > AppConstants.maxLogEntries) {
        final excess = logs.sublist(AppConstants.maxLogEntries);
        final keys = excess.map((l) => l.id).toList();
        await _hiveStorage.deleteAll(AppConstants.logsBox, keys);
        await _hiveStorage.compact(AppConstants.logsBox);
        return logs.sublist(0, AppConstants.maxLogEntries);
      }

      return logs;
    } catch (e) {
      _logger.error('Failed to load logs: $e', e);
      return [];
    }
  }

  Future<void> clearLogs() async {
    await _hiveStorage.clear(AppConstants.logsBox);
    _logger.info('All logs cleared');
  }
}
