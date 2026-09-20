import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/storage/secure_storage_service.dart';
import 'package:logisender/core/telegram/telegram_client.dart';
import 'package:logisender/core/telegram/telegram_client_impl.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:logisender/features/templates/domain/smart_template_engine.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

const _taskName = 'logisender_background_send';
const _taskUniqueName = 'com.logisender.background_send';

Future<void> _initHiveForBackground() async {
  if (Hive.isBoxOpen(AppConstants.groupsBox) ||
      Hive.isBoxOpen(AppConstants.templatesBox)) {
    debugPrint('[BG] Hive already initialized');
    return;
  }

  // Try path_provider first (works via platform channels in workmanager)
  try {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    debugPrint('[BG] Hive initialized via path_provider at ${dir.path}');
    return;
  } catch (e) {
    debugPrint('[BG] path_provider failed: $e');
  }

  // Fallback: known Android paths
  const fallbackPaths = [
    '/data/data/com.example.logisender/app_flutter',
    '/data/user/0/com.example.logisender/app_flutter',
    '/data/data/com.example.logisender/files',
  ];

  for (final path in fallbackPaths) {
    try {
      Hive.init(path);
      debugPrint('[BG] Hive initialized at fallback path: $path');
      return;
    } catch (_) {
      debugPrint('[BG] Hive init failed at fallback path: $path');
    }
  }

  debugPrint('[BG] WARNING: Could not initialize Hive — all paths failed');
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[BG] ════════════════════════════════════════');
    debugPrint('[BG] Task started: $task');
    final sw = Stopwatch()..start();

    try {
      await _initHiveForBackground();

      final logger = LoggerService();
      final secureStorage = SecureStorageService();

      // Skip if in-app automation is currently running to avoid duplicate sends
      if (await secureStorage.isAutomationRunning()) {
        debugPrint('[BG] In-app automation is running, skipping background task');
        return true;
      }

      final apiConfig = await secureStorage.getApiConfig();

      if (apiConfig.isEmpty) {
        debugPrint('[BG] No API config — skipping');
        return true;
      }

      debugPrint('[BG] API config found (apiId=${apiConfig.apiId.toString().substring(0, 2)}****)');

      final client = TelegramClientImpl(
        secureStorage: secureStorage,
        logger: logger,
      );

      debugPrint('[BG] Connecting to Telegram...');
      try {
        await client.connect();
        debugPrint('[BG] Connected to Telegram (${sw.elapsedMilliseconds}ms)');
      } catch (e) {
        debugPrint('[BG] Connect failed: $e');
        return false;
      }

      final hiveStorage = HiveStorageService();

      final rawGroups = await hiveStorage.getAll(AppConstants.groupsBox);
      final rawTemplates = await hiveStorage.getAll(AppConstants.templatesBox);

      debugPrint('[BG] ── Storage dump ──');
      debugPrint('[BG] groupsBox raw count: ${rawGroups.length}');
      debugPrint('[BG] templatesBox raw count: ${rawTemplates.length}');

      for (int i = 0; i < min(rawGroups.length, 5); i++) {
        final item = rawGroups[i];
        debugPrint('[BG]   groups[$i]: type=${item.runtimeType} → $item');
      }
      for (int i = 0; i < min(rawTemplates.length, 5); i++) {
        final item = rawTemplates[i];
        debugPrint('[BG]   templates[$i]: type=${item.runtimeType} → $item');
      }

      final enabledGroups = <TelegramGroup>[];
      for (int i = 0; i < rawGroups.length; i++) {
        try {
          final item = rawGroups[i];
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final group = TelegramGroup.fromJson(map);
            debugPrint('[BG]   → Group ${group.title}: enabled=${group.isEnabled}');
            if (group.isEnabled) enabledGroups.add(group);
          } else {
            debugPrint('[BG]   → groups[$i] is ${item.runtimeType}, not Map');
          }
        } catch (e) {
          debugPrint('[BG]   → groups[$i] parse error: $e');
        }
      }

      final templates = <AdTemplate>[];
      for (int i = 0; i < rawTemplates.length; i++) {
        try {
          final item = rawTemplates[i];
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final tpl = AdTemplate.fromJson(map);
            debugPrint('[BG]   → Template ${tpl.name}: isSmart=${tpl.isSmart}');
            templates.add(tpl);
          } else {
            debugPrint('[BG]   → templates[$i] is ${item.runtimeType}, not Map');
          }
        } catch (e) {
          debugPrint('[BG]   → templates[$i] parse error: $e');
        }
      }

      debugPrint('[BG] Result: ${enabledGroups.length} enabled groups, ${templates.length} templates');

      if (enabledGroups.isEmpty || templates.isEmpty) {
        debugPrint('[BG] Nothing to send — skipping (groups=${enabledGroups.length}, templates=${templates.length})');
        await client.disconnect();
        return true;
      }

      final random = Random();

      for (final group in enabledGroups) {
        final source = templates[random.nextInt(templates.length)];
        final text = source.isSmart
            ? SmartTemplateEngine.generateVariation(source.text)
            : source.text;

        final result = await client.sendMessage(
          chatId: group.id,
          text: text,
          peerType: group.type,
          accessHash: group.accessHash,
        );

        switch (result) {
          case SendMessageSuccess():
            logger.info('[BG] Sent to ${group.title}');
          case SendMessageFloodWait(:final seconds):
            logger.warning('[BG] FloodWait for ${group.title}: ${seconds}s');
          case SendMessageSlowMode(:final seconds):
            logger.warning('[BG] SlowMode for ${group.title}: ${seconds}s');
          case SendMessageError(:final message):
            logger.warning('[BG] Failed for ${group.title}: $message');
        }

        if (group != enabledGroups.last) {
          final delay = 20 + random.nextInt(41);
          await Future.delayed(Duration(seconds: delay));
        }
      }

      await client.disconnect();
      sw.stop();
      debugPrint('[BG] Task completed in ${sw.elapsedMilliseconds}ms');
      return true;
    } catch (e, st) {
      debugPrint('[BG] Task failed: $e');
      debugPrint('[BG] Stack: $st');
      return false;
    }
  });
}

Future<void> initBackgroundScheduler() async {
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    _taskUniqueName,
    _taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 5),
  );

  debugPrint('[BG] Periodic background task registered (every 15 min)');
}

Future<void> cancelBackgroundScheduler() async {
  await Workmanager().cancelAll();
  debugPrint('[BG] All background tasks cancelled');
}
