import 'package:logisender/core/telegram/telegram_client.dart';
import 'package:logisender/core/telegram/telegram_models.dart';

/// Repository for automation sending operations.
class AutomationRepository {
  final TelegramClient _client;

  AutomationRepository({required TelegramClient client}) : _client = client;

  Future<SendMessageResult> sendMessageToGroup({
    required TelegramGroup group,
    required String text,
  }) async {
    return _client.sendMessage(
      chatId: group.id,
      text: text,
      peerType: group.type,
      accessHash: group.accessHash,
    );
  }

  Future<bool> editMessageInGroup({
    required int chatId,
    required int messageId,
    required String text,
  }) async {
    return _client.editMessage(chatId: chatId, messageId: messageId, text: text);
  }

  Future<bool> deleteMessageFromGroup({
    required int chatId,
    required int messageId,
  }) async {
    return _client.deleteMessages(chatId: chatId, messageIds: [messageId]);
  }
}
