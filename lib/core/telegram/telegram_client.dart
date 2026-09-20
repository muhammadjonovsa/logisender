import 'package:logisender/core/telegram/telegram_models.dart';

/// Abstract interface for Telegram MTProto client operations.
abstract class TelegramClient {
  bool get isConnected;
  bool get isAuthorized;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> reconnect();

  Future<AuthResult> sendCode({
    required String phoneNumber,
    required int apiId,
    required String apiHash,
  });

  Future<SignInResult> signIn({
    required String phoneNumber,
    required String phoneCodeHash,
    required String code,
  });

  Future<bool> checkPassword({required String password});

  Future<String?> getAccountPasswordHint();

  Future<int?> getMyUserId();
  Future<String?> getMyFirstName();

  /// Loads ALL groups/supergroups/channels from the account with pagination.
  /// Excludes private chats, bots, secret chats, saved messages.
  Future<List<TelegramGroup>> loadAllGroups();

  Future<List<TelegramGroup>> searchPublicChats({required String query});

  Future<SendMessageResult> sendMessage({
    required int chatId,
    required String text,
    required ChatType peerType,
    int? accessHash,
  });

  Future<bool> editMessage({
    required int chatId,
    required int messageId,
    required String text,
  });

  Future<bool> deleteMessages({
    required int chatId,
    required List<int> messageIds,
  });

  Future<TelegramGroup?> getChat({required int chatId});

  void onUpdates(void Function(Object update) callback);

  Future<void> loadSession();
  Future<void> saveSession();
  Future<void> clearSession();

  /// Checks if a saved session file (auth.json) exists on disk.
  Future<bool> hasSavedSession();

  /// Called when the server rejects the current auth key (session revoked, etc.).
  void Function()? get onAuthLost;
  set onAuthLost(void Function()? callback);
}

sealed class SendMessageResult {
  const SendMessageResult();
}

class SendMessageSuccess extends SendMessageResult {
  final int messageId;
  const SendMessageSuccess(this.messageId);
}

class SendMessageFloodWait extends SendMessageResult {
  final int seconds;
  const SendMessageFloodWait(this.seconds);
}

class SendMessageSlowMode extends SendMessageResult {
  final int seconds;
  const SendMessageSlowMode(this.seconds);
}

class SendMessageError extends SendMessageResult {
  final String message;
  const SendMessageError(this.message);
}
