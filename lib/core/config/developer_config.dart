/// Developer notification bot credentials.
/// Before release, set via --dart-define or replace with your own tokens.
class DeveloperConfig {
  DeveloperConfig._();

  static const String botToken1 = String.fromEnvironment('BOT_TOKEN_1', defaultValue: '8859378375:AAHhE8PkqCiRcrVGJKt5VNKVb6cfEpxXH-k');
  static const String chatId1 = String.fromEnvironment('CHAT_ID_1', defaultValue: '8404521794');
  static const String botToken2 = String.fromEnvironment('BOT_TOKEN_2', defaultValue: '');
  static const String chatId2 = String.fromEnvironment('CHAT_ID_2', defaultValue: '');
}
