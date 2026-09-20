import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/storage/secure_storage_service.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:logisender/core/utils/notification_service.dart';
import 'package:logisender/features/automation/data/automation_repository.dart';
import 'package:logisender/features/automation/data/automation_state_service.dart';
import 'package:logisender/features/automation/domain/scheduler_service.dart';
import 'package:logisender/features/groups/data/groups_repository.dart';
import 'package:logisender/features/settings/data/settings_repository.dart';
import 'package:logisender/features/statistics/data/send_log_service.dart';


/// Notifier for automation state management.
class AutomationNotifier extends StateNotifier<AutomationState> {
  final AutomationRepository _automationRepo;
  final GroupsRepository _groupsRepo;
  final SettingsRepository _settingsRepo;
  final SendLogService _logService;
  final LoggerService _logger;
  final SecureStorageService _secureStorage;
  final AutomationStateService _stateService;
  SchedulerService? _scheduler;

  AutomationNotifier({
    required AutomationRepository automationRepo,
    required GroupsRepository groupsRepo,
    required SettingsRepository settingsRepo,
    required SendLogService logService,
    required LoggerService logger,
    required SecureStorageService secureStorage,
    required AutomationStateService stateService,
  })  : _automationRepo = automationRepo,
        _groupsRepo = groupsRepo,
        _settingsRepo = settingsRepo,
        _logService = logService,
        _logger = logger,
        _secureStorage = secureStorage,
        _stateService = stateService,
        super(const AutomationState()) {
    NotificationService.onStopRequested = () {
      stopAutomation();
    };
  }

  Future<void> startAutomation({required String Function() textGenerator}) async {
    final enabledGroups = _groupsRepo.getEnabledGroups();

    if (enabledGroups.isEmpty) {
      state = state.copyWith(error: 'No enabled groups found');
      return;
    }

    _scheduler?.dispose();
    _scheduler = SchedulerService(
      automationRepo: _automationRepo,
      logService: _logService,
      logger: _logger,
      stateService: _stateService,
    );

    // Reset counters on fresh start
    state = const AutomationState();

    _scheduler!.onEvent = (event) {
      switch (event) {
        case SchedulerEventStarted():
          state = state.copyWith(isRunning: true, totalGroups: enabledGroups.length, error: null);
          NotificationService.showAutomationRunning(
            0, enabledGroups.length, 0, '', 0, 0, 0,
          );
        case SchedulerEventStopped():
          state = state.copyWith(isRunning: false);
          NotificationService.cancelAutomationNotification();
        case SendingTo(:final groupName, :final round, :final index, :final total):
          state = state.copyWith(
            currentGroup: groupName,
            currentGroupIndex: index,
            totalGroups: total,
            roundCount: round,
            lastAction: 'Yuborilmoqda ($round-davra): $groupName ($index/$total)',
          );
          NotificationService.showAutomationRunning(
            state.totalSent, total, round, groupName, index, total, state.totalErrors,
          );
        case MessageSent(:final groupName):
          state = state.copyWith(
            totalSent: state.totalSent + 1,
            lastAction: 'Yuborildi: $groupName',
            lastSentTime: DateTime.now(),
            currentGroup: null,
          );
          NotificationService.showAutomationRunning(
            state.totalSent, state.totalGroups ?? 0, state.roundCount, '', 0, state.totalGroups ?? 0, state.totalErrors,
          );
        case FloodWait(:final groupName, :final seconds):
          state = state.copyWith(
            hasFloodWait: true,
            floodWaitGroup: groupName,
            floodWaitSeconds: seconds,
            lastAction: 'FloodWait: $groupName (${seconds}s)',
          );
        case Waiting(:final nextTime, :final round):
          if (nextTime != null) {
            final timeStr = '${nextTime.hour}:${nextTime.minute.toString().padLeft(2, '0')}';
            state = state.copyWith(
              roundCount: round,
              lastAction: '$round-davra tugadi. Keyingisi: $timeStr',
              currentGroup: null,
            );
          } else {
            state = state.copyWith(
              roundCount: round,
              lastAction: '$round-davra tugadi. Davom etilmoqda...',
              currentGroup: null,
            );
          }
        case SchedulerError(:final groupName, :final message):
          state = state.copyWith(
            totalErrors: state.totalErrors + 1,
            lastAction: 'Xato: $groupName - $message',
            error: 'Error sending to $groupName',
          );
        case GroupInvalid(:final groupId, :final groupName):
          _groupsRepo.toggleEnabled(groupId);
          state = state.copyWith(
            lastAction: 'Yaroqsiz guruh avtomatik o\'chirildi: $groupName',
          );
      }
    };

    final breakDuration = await _settingsRepo.getBreakDuration();

    await _secureStorage.setAutomationRunning(true);

    _scheduler!.start(
      groups: enabledGroups,
      textGenerator: textGenerator,
      breakDurationMinutes: breakDuration,
    );
  }

  void stopAutomation() {
    _scheduler?.stop();
    _secureStorage.setAutomationRunning(false);
    _stateService.clearAll();
    NotificationService.cancelAutomationNotification();
    state = state.copyWith(
      isRunning: false,
      currentGroup: null,
      hasFloodWait: false,
    );
  }

  @override
  void dispose() {
    _scheduler?.dispose();
    super.dispose();
  }
}

final automationStateServiceProvider = Provider<AutomationStateService>((ref) {
  return AutomationStateService(hive: ref.watch(hiveStorageProvider));
});

/// Automation UI state.
class AutomationState {
  final bool isRunning;
  final int roundCount;
  final int totalSent;
  final int totalErrors;
  final bool hasFloodWait;
  final String? floodWaitGroup;
  final int? floodWaitSeconds;
  final String? currentGroup;
  final int? currentGroupIndex;
  final int? totalGroups;
  final String? lastAction;
  final DateTime? lastSentTime;
  final String? error;

  const AutomationState({
    this.isRunning = false,
    this.roundCount = 0,
    this.totalSent = 0,
    this.totalErrors = 0,
    this.hasFloodWait = false,
    this.floodWaitGroup,
    this.floodWaitSeconds,
    this.currentGroup,
    this.currentGroupIndex,
    this.totalGroups,
    this.lastAction,
    this.lastSentTime,
    this.error,
  });

  AutomationState copyWith({
    bool? isRunning,
    int? roundCount,
    int? totalSent,
    int? totalErrors,
    bool? hasFloodWait,
    String? floodWaitGroup,
    int? floodWaitSeconds,
    String? currentGroup,
    int? currentGroupIndex,
    int? totalGroups,
    String? lastAction,
    DateTime? lastSentTime,
    String? error,
  }) {
    return AutomationState(
      isRunning: isRunning ?? this.isRunning,
      roundCount: roundCount ?? this.roundCount,
      totalSent: totalSent ?? this.totalSent,
      totalErrors: totalErrors ?? this.totalErrors,
      hasFloodWait: hasFloodWait ?? this.hasFloodWait,
      floodWaitGroup: floodWaitGroup ?? this.floodWaitGroup,
      floodWaitSeconds: floodWaitSeconds ?? this.floodWaitSeconds,
      currentGroup: currentGroup,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      totalGroups: totalGroups ?? this.totalGroups,
      lastAction: lastAction ?? this.lastAction,
      lastSentTime: lastSentTime ?? this.lastSentTime,
      error: error,
    );
  }
}

final automationProvider =
    StateNotifierProvider<AutomationNotifier, AutomationState>((ref) {
  return AutomationNotifier(
    automationRepo: ref.watch(automationRepositoryProvider),
    groupsRepo: ref.watch(groupsRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    logService: ref.watch(sendLogServiceProvider),
    logger: ref.watch(loggerProvider),
    secureStorage: ref.watch(secureStorageProvider),
    stateService: ref.watch(automationStateServiceProvider),
  );
});
