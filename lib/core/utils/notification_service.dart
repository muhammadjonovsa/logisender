import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'automation_channel';
  static const String _channelName = 'Automation Service';
  static const int _notificationId = 888;

  static DateTime? _lastShownAt;
  static Function()? onStopRequested;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == 'stop_automation' || details.actionId == 'stop_action') {
          onStopRequested?.call();
        }
      },
    );

    _requestNotificationPermission();
  }

  static Future<void> _requestNotificationPermission() async {
    try {
      if (await Permission.notification.status.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  static Future<void> showAutomationRunning(
    int totalSent,
    int totalGroups,
    int round,
    String currentGroup,
    int currentIndex,
    int total,
    int totalErrors,
  ) async {
    // Throttle updates to avoid spamming the platform channel (which blocks the
    // main thread) during long automation runs with many groups.
    const throttle = Duration(seconds: 2);
    final now = DateTime.now();
    if (_lastShownAt != null && now.difference(_lastShownAt!) < throttle) {
      return;
    }
    _lastShownAt = now;

    final body = currentGroup.isEmpty
        ? 'Yuborildi: $totalSent / $totalGroups | Xatolar: $totalErrors | Davra: $round'
        : '(${currentIndex + 1}/$total) $currentGroup | Davra: $round';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      color: Color(0xFF58A6FF),
      actions: [
        AndroidNotificationAction(
          'stop_action',
          'To\'xtatish',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notifications.show(
      _notificationId,
      'LogiSender: Avtomatlashtirish',
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'stop_automation',
    );
  }

  static Future<void> cancelAutomationNotification() async {
    await _notifications.cancel(_notificationId);
  }
}
