import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/telegram/telegram_client.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:logisender/features/automation/data/automation_repository.dart';
import 'package:logisender/features/automation/data/automation_state_service.dart';
import 'package:logisender/features/statistics/data/send_log_service.dart';

/// Scheduler service for managing automated message sending.
/// Implements round-based sending: all groups one by one, then a long break.
class SchedulerService {
  final AutomationRepository _automationRepo;
  final SendLogService _logService;
  final LoggerService _logger;
  final AutomationStateService _stateService;
  
  final Random _random = Random();
  bool _isRunning = false;
  bool _shouldStop = false;
  DateTime? _nextRoundTime;
  int _currentRound = 0;

  void Function(SchedulerEvent event)? onEvent;

  SchedulerService({
    required AutomationRepository automationRepo,
    required SendLogService logService,
    required LoggerService logger,
    required AutomationStateService stateService,
  })  : _automationRepo = automationRepo,
        _logService = logService,
        _logger = logger,
        _stateService = stateService;

  bool get isRunning => _isRunning;
  DateTime? get nextRoundTime => _nextRoundTime;
  int get currentRound => _currentRound;

  void start({
    required List<TelegramGroup> groups,
    required String Function() textGenerator,
    int? breakDurationMinutes,
  }) {
    if (_isRunning) return;

    _isRunning = true;
    _shouldStop = false;
    
    _logger.info('Scheduler started with ${groups.length} groups (Round-based)');
    onEvent?.call(SchedulerEvent.started);

    _runAutomationLoop(groups, textGenerator, breakDurationMinutes);
  }

  void stop() {
    _shouldStop = true;
    _isRunning = false;
    _nextRoundTime = null;

    _logger.info('Scheduler stopped');
    onEvent?.call(SchedulerEvent.stopped);
  }


  Future<void> _runAutomationLoop(
    List<TelegramGroup> groups,
    String Function() textGenerator,
    int? breakDurationMinutes,
  ) async {
    while (!_shouldStop && _isRunning) {
      _currentRound++;
      _logger.info('═══ Starting round $_currentRound ═══');
      try {
        await _runSingleRound(groups, textGenerator, breakDurationMinutes);
      } catch (e, st) {
        _logger.error('Scheduler round crashed, restarting in 10s: $e');
        debugPrint('[Scheduler] Round crash stack: $st');
        onEvent?.call(SchedulerEvent.error('', 'Round crashed: $e'));
        if (!_shouldStop) {
          for (int s = 0; s < 10 && !_shouldStop; s++) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
    }
  }

  Future<void> _runSingleRound(
    List<TelegramGroup> groups,
    String Function() textGenerator,
    int? breakDurationMinutes,
  ) async {
    final enabledGroups = groups.where((g) => g.isEnabled).toList();
    
    if (enabledGroups.isEmpty) {
      _logger.warning('No enabled groups to send to');
      await Future.delayed(const Duration(minutes: 5));
      return;
    }

    _logger.info('Starting new sending round for ${enabledGroups.length} groups');
    enabledGroups.shuffle(_random);

    for (int i = 0; i < enabledGroups.length; i++) {
      if (_shouldStop) break;

      const maxRetries = 3;
      int totalFloodWaitSeconds = 0;

      for (int r = 0; r < maxRetries; r++) {
        if (_shouldStop) break;

        final group = enabledGroups[i];
        onEvent?.call(SchedulerEvent.sendingTo(group.title, round: _currentRound, index: i, total: enabledGroups.length));

        final text = textGenerator();
        
        try {
          final result = await _automationRepo.sendMessageToGroup(
            group: group,
            text: text,
          ).timeout(const Duration(seconds: 30));

          if (result is SendMessageFloodWait) {
            _logger.floodWait(group.title, result.seconds);
            _logService.logSend(
              chatId: group.id,
              chatName: group.title,
              templateId: '',
              messageText: text,
              status: SentStatus.floodWait,
              floodWaitSeconds: result.seconds,
            );
            final waitSeconds = (result.seconds + 5).clamp(5, 300);
            totalFloodWaitSeconds += waitSeconds;
            if (totalFloodWaitSeconds > 600) {
              _logger.error('Total FloodWait >10min for ${group.title}, skipping');
              onEvent?.call(SchedulerEvent.error(group.title, 'FloodWait too long'));
              await _stateService.clearFloodWait();
              break;
            }
            _logger.info('FloodWait on ${group.title}, waiting ${waitSeconds}s before retry');
            onEvent?.call(SchedulerEvent.floodWait(group.title, waitSeconds));
            // Persist deadline so app can skip if relaunched after OS kill
            await _stateService.saveFloodWait(
              floodWaitUntil: DateTime.now().add(Duration(seconds: waitSeconds)),
              groupName: group.title,
            );
            for (int s = 0; s < waitSeconds && !_shouldStop; s += 5) {
              await Future.delayed(const Duration(seconds: 5));
            }
            await _stateService.clearFloodWait();
            if (!_shouldStop) {
              r--; // Don't consume retry counter for FloodWait
              continue;
            }
            break;
          }

          if (result is SendMessageSlowMode) {
            _logger.warning('SlowMode on ${group.title}, skipping for this round');
            _logService.logSend(
              chatId: group.id,
              chatName: group.title,
              templateId: '',
              messageText: text,
              status: SentStatus.failed,
              errorMessage: 'SlowMode',
            );
            break;
          }

          if (result is SendMessageError) {
            final msg = result.message.toUpperCase();
            if (msg.contains('PEER_ID_INVALID') || msg.contains('CHANNEL_PRIVATE') || msg.contains('USER_BANNED_IN_CHANNEL')) {
              _logger.error('Invalid group ${group.title}, auto-removing from queue: ${result.message}');
              onEvent?.call(SchedulerEvent.groupInvalid(group.id, group.title));
              _logService.logSend(
                chatId: group.id,
                chatName: group.title,
                templateId: '',
                messageText: text,
                status: SentStatus.failed,
                errorMessage: 'Group Invalid: ${result.message}',
              );
              break;
            }

            if (r < maxRetries - 1) {
              final backoffSeconds = pow(2, r + 1) * 2;
              _logger.error('Error on ${group.title}, retry ${r + 1}/$maxRetries in ${backoffSeconds}s: ${result.message}');
              await Future.delayed(Duration(seconds: backoffSeconds.toInt()));
              continue;
            }
            _handleResult(result, group, text);
            _logger.error('Max retries ($maxRetries) reached, skipping ${group.title}: ${result.message}');
            break;
          }

          // Must be success
          _handleResult(result, group, text);
        } catch (e) {
          if (r < maxRetries - 1) {
            final backoffSeconds = pow(2, r + 1) * 2;
            _logger.error('Error sending to ${group.title}, retry ${r + 1}/$maxRetries in ${backoffSeconds}s: $e');
            await Future.delayed(Duration(seconds: backoffSeconds.toInt()));
            continue;
          }
          _logger.error('Max retries ($maxRetries) reached for ${group.title}: $e');
          onEvent?.call(SchedulerEvent.error(group.title, 'Failed after $maxRetries retries'));
        }
        break;
      }

      if (_shouldStop) break;

      if (i < enabledGroups.length - 1 && !_shouldStop) {
        final delay = AppConstants.groupSwitchMinSeconds + 
                      _random.nextInt(AppConstants.groupSwitchMaxSeconds - AppConstants.groupSwitchMinSeconds + 1);
        debugPrint('[Scheduler] Waiting ${delay}s before next group');
        await Future.delayed(Duration(seconds: delay));
      }
    }

    // Break between rounds
    await _stateService.saveRound(_currentRound);
    final breakSeconds = (breakDurationMinutes ?? (AppConstants.minSendIntervalSeconds ~/ 60)) * 60;
    if (breakSeconds > 0) {
      _nextRoundTime = DateTime.now().add(Duration(seconds: breakSeconds));
      onEvent?.call(SchedulerEvent.waiting(_nextRoundTime!, round: _currentRound));
      _logger.info('Round $_currentRound finished. Next round at: ${_nextRoundTime!.hour}:${_nextRoundTime!.minute.toString().padLeft(2, '0')} (${breakSeconds ~/ 60} min break)');
      while (DateTime.now().isBefore(_nextRoundTime!) && !_shouldStop) {
        await Future.delayed(const Duration(seconds: 30));
      }
    } else {
      _nextRoundTime = null;
      onEvent?.call(SchedulerEvent.waiting(null, round: _currentRound));
      _logger.info('Round $_currentRound finished. No break, starting next round immediately.');
    }
  }

  void _handleResult(SendMessageResult result, TelegramGroup group, String text) {
    switch (result) {
      case SendMessageSuccess():
        _logger.sent(group.title, text);
        onEvent?.call(SchedulerEvent.messageSent(group.title));
        _logService.logSend(
          chatId: group.id,
          chatName: group.title,
          templateId: '',
          messageText: text,
          status: SentStatus.sent,
        );

      case SendMessageError(:final message):
        _logger.error('Send failed to ${group.title}: $message');
        onEvent?.call(SchedulerEvent.error(group.title, message));
        _logService.logSend(
          chatId: group.id,
          chatName: group.title,
          templateId: '',
          messageText: text,
          status: SentStatus.failed,
          errorMessage: message,
        );

      default:
    }
  }

  void dispose() {
    stop();
  }
}

/// Events emitted by the scheduler.
sealed class SchedulerEvent {
  const SchedulerEvent();

  static const started = SchedulerEventStarted();
  static const stopped = SchedulerEventStopped();

  static SendingTo sendingTo(String groupName, {int round = 0, int index = 0, int total = 0}) =>
      SendingTo(groupName, round: round, index: index, total: total);
  static MessageSent messageSent(String groupName) => MessageSent(groupName);
  static FloodWait floodWait(String groupName, int seconds) =>
      FloodWait(groupName, seconds);
  static Waiting waiting(DateTime? nextTime, {int round = 0}) =>
      Waiting(nextTime, round: round);
  static SchedulerError error(String groupName, String message) =>
      SchedulerError(groupName, message);
  static GroupInvalid groupInvalid(int groupId, String groupName) =>
      GroupInvalid(groupId, groupName);
}

class SchedulerEventStarted extends SchedulerEvent {
  const SchedulerEventStarted();
}

class SchedulerEventStopped extends SchedulerEvent {
  const SchedulerEventStopped();
}

class SendingTo extends SchedulerEvent {
  final String groupName;
  final int round;
  final int index;
  final int total;
  const SendingTo(this.groupName, {this.round = 0, this.index = 0, this.total = 0});
}

class MessageSent extends SchedulerEvent {
  final String groupName;
  const MessageSent(this.groupName);
}

class FloodWait extends SchedulerEvent {
  final String groupName;
  final int seconds;
  const FloodWait(this.groupName, this.seconds);
}

class Waiting extends SchedulerEvent {
  final DateTime? nextTime;
  final int round;
  const Waiting(this.nextTime, {this.round = 0});
}

class SchedulerError extends SchedulerEvent {
  final String groupName;
  final String message;
  const SchedulerError(this.groupName, this.message);
}

class GroupInvalid extends SchedulerEvent {
  final int groupId;
  final String groupName;
  const GroupInvalid(this.groupId, this.groupName);
}
