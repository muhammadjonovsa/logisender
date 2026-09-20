import 'dart:async';

import 'package:logger/logger.dart';

/// Singleton logging service with in-memory log buffer.
final class LoggerService {
  static final LoggerService _instance = LoggerService._();
  factory LoggerService() => _instance;

  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  final List<LogEntry> _entries = [];
  final StreamController<List<LogEntry>> _logStreamController =
      StreamController<List<LogEntry>>.broadcast();

  Stream<List<LogEntry>> get logStream => _logStreamController.stream;
  List<LogEntry> get entries => List.unmodifiable(_entries);

  LoggerService._();

  void info(String message) {
    _addEntry(LogLevel.info, message);
    _logger.i(message);
  }

  void warning(String message) {
    _addEntry(LogLevel.warning, message);
    _logger.w(message);
  }

  void error(String message, [Object? exception]) {
    _addEntry(LogLevel.error, message);
    _logger.e(message, error: exception);
  }

  void debug(String message) {
    _addEntry(LogLevel.debug, message);
    _logger.d(message);
  }

  void sent(String chatName, String message) {
    final preview = message.length > 50 ? '${message.substring(0, 50)}...' : message;
    _addEntry(LogLevel.sent, 'Sent to $chatName: $preview');
  }

  void floodWait(String chatName, int seconds) {
    _addEntry(LogLevel.floodWait, 'FloodWait on $chatName: ${seconds}s');
  }

  void retry(String chatName, int attempt) {
    _addEntry(LogLevel.retry, 'Retry #$attempt for $chatName');
  }

  void _addEntry(LogLevel level, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    _entries.insert(0, entry);
    if (_entries.length > 500) {
      _entries.removeRange(500, _entries.length);
    }
    // Only build the immutable snapshot if something is actually listening.
    // During automation the list is mutated on every event; copying it each
    // time on the main thread contributes to UI jank.
    if (_logStreamController.hasListener) {
      _logStreamController.add(List.unmodifiable(_entries));
    }
  }

  void clear() {
    _entries.clear();
    _logStreamController.add([]);
  }

  void dispose() {
    _logStreamController.close();
  }
}

/// Log level enumeration.
enum LogLevel {
  info,
  warning,
  error,
  debug,
  sent,
  floodWait,
  retry,
}

/// A single log entry.
final class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  String get levelIcon {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.debug:
        return '🔍';
      case LogLevel.sent:
        return '✅';
      case LogLevel.floodWait:
        return '⏳';
      case LogLevel.retry:
        return '🔄';
    }
  }
}
