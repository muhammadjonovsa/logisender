import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/features/statistics/data/statistics_repository.dart';
import 'package:logisender/features/statistics/data/send_log_service.dart';

enum StatsPeriod { today, yesterday, week, month }

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final StatisticsRepository _repository;
  final SendLogService _logService;

  StatisticsNotifier(this._repository, this._logService) : super(const StatisticsState());

  void setPeriod(StatsPeriod period) {
    state = state.copyWith(selectedPeriod: period);
    refresh();
  }

  Future<void> refresh() async {
    try {
      final logs = await _logService.loadLogs();
      StatsSummary summary;
      switch (state.selectedPeriod) {
        case StatsPeriod.today:
          summary = _repository.getTodayStats(logs);
        case StatsPeriod.yesterday:
          summary = _repository.getYesterdayStats(logs);
        case StatsPeriod.week:
          summary = _repository.getWeekStats(logs);
        case StatsPeriod.month:
          summary = _repository.getMonthStats(logs);
      }
      if (!mounted) return;
      state = state.copyWith(summary: summary, logs: logs);
    } catch (e) {
      debugPrint('[StatsNotifier] refresh ERROR: $e');
    }
  }
}

class StatisticsState {
  final StatsPeriod selectedPeriod;
  final StatsSummary summary;
  final List<SendLog> logs;

  const StatisticsState({
    this.selectedPeriod = StatsPeriod.today,
    this.summary = const StatsSummary(),
    this.logs = const [],
  });

  StatisticsState copyWith({
    StatsPeriod? selectedPeriod,
    StatsSummary? summary,
    List<SendLog>? logs,
  }) {
    return StatisticsState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      summary: summary ?? this.summary,
      logs: logs ?? this.logs,
    );
  }
}

final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier(
    ref.watch(statisticsRepositoryProvider),
    ref.watch(sendLogServiceProvider),
  );
});
