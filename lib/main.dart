import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/background/background_task_handler.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/utils/notification_service.dart';
import 'package:logisender/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await HiveStorageService.init();
  await NotificationService.init();
  await initBackgroundScheduler();

  runApp(
    const ProviderScope(
      child: LogiSenderApp(),
    ),
  );
}
