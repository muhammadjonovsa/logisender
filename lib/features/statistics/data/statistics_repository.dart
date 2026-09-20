import 'package:logisender/core/telegram/telegram_models.dart';

/// Repository for statistics data aggregation.
class StatisticsRepository {
  StatsSummary getTodayStats(List<SendLog> logs) {
    final now = DateTime.now();
    final todayLogs = logs.where((l) =>
        l.sentTime.year == now.year &&
        l.sentTime.month == now.month &&
        l.sentTime.day == now.day);
    return _aggregate(todayLogs.toList());
  }

  StatsSummary getYesterdayStats(List<SendLog> logs) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayLogs = logs.where((l) =>
        l.sentTime.year == yesterday.year &&
        l.sentTime.month == yesterday.month &&
        l.sentTime.day == yesterday.day);
    return _aggregate(yesterdayLogs.toList());
  }

  StatsSummary getWeekStats(List<SendLog> logs) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekLogs = logs.where((l) => l.sentTime.isAfter(weekAgo));
    return _aggregate(weekLogs.toList());
  }

  StatsSummary getMonthStats(List<SendLog> logs) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month - 1, now.day);
    final monthLogs = logs.where((l) => l.sentTime.isAfter(firstOfMonth));
    return _aggregate(monthLogs.toList());
  }

  StatsSummary _aggregate(List<SendLog> logs) {
    int sent = 0;
    int errors = 0;
    int floodWaits = 0;

    for (final log in logs) {
      switch (log.status) {
        case SentStatus.sent:
          sent++;
        case SentStatus.failed:
          errors++;
        case SentStatus.floodWait:
          floodWaits++;
        case SentStatus.pending:
        case SentStatus.retrying:
          break;
      }
    }

    return StatsSummary(
      totalSent: logs.length,
      totalErrors: errors,
      floodWaitCount: floodWaits,
      successfulSends: sent,
    );
  }
}
