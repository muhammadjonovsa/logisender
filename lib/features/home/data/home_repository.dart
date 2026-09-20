import 'package:logisender/core/telegram/telegram_client.dart';

/// Repository for home dashboard data operations.
class HomeRepository {
  final TelegramClient _client;

  HomeRepository({required TelegramClient client}) : _client = client;

  bool get isConnected => _client.isConnected;
  bool get isAuthorized => _client.isAuthorized;

  Future<int?> getMyUserId() async => _client.getMyUserId();
  Future<String?> getMyFirstName() async => _client.getMyFirstName();

  // activeCount is now computed from groupsProvider in the UI,
  // NOT from loadAllGroups() to avoid double Telegram API call.
}
