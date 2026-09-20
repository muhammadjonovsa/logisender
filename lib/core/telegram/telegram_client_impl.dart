import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logisender/core/storage/secure_storage_service.dart';
import 'package:logisender/core/telegram/telegram_client.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:tg/tg.dart' as tg;
import 'package:t/t.dart' as t;

enum _ConnState { disconnected, connecting, connected, reconnecting }

class _ManagedSocket extends tg.SocketAbstraction {
  _ManagedSocket(Socket socket) : _socket = socket {
    _subscription = _socket.listen(
      (data) => _controller.add(Uint8List.fromList(data)),
      onError: (e) => _controller.addError(e),
      onDone: () {
        if (!_controller.isClosed) _controller.close();
      },
      cancelOnError: false,
    );
  }

  final Socket _socket;
  StreamSubscription<Uint8List>? _subscription;
  final _controller = StreamController<Uint8List>.broadcast();
  bool _isClosed = false;

  @override
  Stream<Uint8List> get receiver => _controller.stream;

  @override
  Future<void> send(List<int> data) async {
    if (_isClosed) throw const SocketException('Socket already closed');
    _socket.add(data);
    await _socket.flush();
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _socket.close();
    } catch (_) {}
    _socket.destroy();
    if (!_controller.isClosed) await _controller.close();
  }
}

class TelegramClientImpl implements TelegramClient {
  final SecureStorageService _secureStorage;
  final LoggerService _logger;

  _ManagedSocket? _managedSocket;
  tg.Client? _client;

  _ConnState _state = _ConnState.disconnected;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Completer<void>? _connectCompleter;

  bool _authorized = false;
  int? _myUserId;
  String? _myFirstName;
  String? _lastPhoneNumber;
  t.AccountPassword? _accountPassword;
  ApiConfig _apiConfig = ApiConfig.empty();
  tg.AuthorizationKey? _savedAuthKey;

  static const _defaultDcIp = '149.154.167.50';
  static const _defaultDcPort = 443;
  static const _pingInterval = Duration(seconds: 30);
  static const _pingTimeout = Duration(seconds: 10);
  static const _maxReconnectDelay = 30;
  static const _socketConnectTimeout = Duration(seconds: 15);
  static const _initConnectionTimeout = Duration(seconds: 20);

  void Function()? _onAuthLost;
  @override
  void Function()? get onAuthLost => _onAuthLost;
  @override
  set onAuthLost(void Function()? callback) => _onAuthLost = callback;

  TelegramClientImpl({
    required SecureStorageService secureStorage,
    required LoggerService logger,
  })  : _secureStorage = secureStorage,
        _logger = logger;

  @override
  bool get isConnected => _client != null && _state == _ConnState.connected;

  @override
  bool get isAuthorized => _authorized;

  @override
  Future<void> connect() async {
    if (_state == _ConnState.connected) return;
    if ((_state == _ConnState.connecting || _state == _ConnState.reconnecting) && _connectCompleter != null) {
      return _connectCompleter!.future;
    }

    _state = _ConnState.connecting;
    _connectCompleter = Completer<void>();

    try {
      _logger.info('connect() starting...');
      _cancelPing();
      _apiConfig = await _secureStorage.getApiConfig();
      if (_apiConfig.isEmpty) throw Exception('API Config missing');

      await _cleanupSocket();
      _cancelReconnectTimer();

      final socket = await Socket.connect(
        _defaultDcIp, _defaultDcPort,
        timeout: _socketConnectTimeout,
      );

      final managedSocket = _ManagedSocket(socket);
      _managedSocket = managedSocket;

      final obfuscation = tg.Obfuscation.random(false, 1);
      final idGen = tg.MessageIdGenerator();
      await managedSocket.send(obfuscation.preamble);

      _savedAuthKey = await _loadSession();

      final authKey = _savedAuthKey ?? await tg.Client.authorize(managedSocket, obfuscation, idGen).timeout(const Duration(seconds: 15));

      final newClient = tg.Client(
        socket: managedSocket,
        obfuscation: obfuscation,
        authorizationKey: authKey,
        idGenerator: idGen,
      );

      await newClient.initConnection<t.Config>(
        apiId: _apiConfig.apiId,
        deviceModel: 'LogiSenderapp',
        systemVersion: 'LogiSender Pro',
        appVersion: '1.0.0',
        systemLangCode: 'en',
        langPack: '',
        langCode: 'en',
        query: const t.HelpGetConfig(),
      ).timeout(_initConnectionTimeout);

      // Only watch for socket death after connection is fully established
      unawaited(socket.done.whenComplete(() => _onConnectionLost()));

      _client = newClient;
      _state = _ConnState.connected;
      _reconnectAttempt = 0;
      _authorized = false;
      _startPing();
      _logger.info('Connected successfully');
    } catch (e) {
      _logger.error('connect() FAILED: $e');
      final errorMsg = e.toString();

      // Detect Telegram auth key rejection — trigger re-login
      final isAuthRejection = errorMsg.contains('AUTH_KEY_UNREGISTERED') ||
          errorMsg.contains('SESSION_REVOKED') ||
          errorMsg.contains('ACTIVE_USER_REQUIRED');
      if (isAuthRejection) {
        _logger.warning('Auth key rejected by server, clearing session');
        await clearSession();
      }

      _state = _ConnState.disconnected;
      _client = null;
      _cancelPing();
      if (isAuthRejection) {
        _authorized = false;
        _onAuthLost?.call();
      }
      await _cleanupSocket();
      if (!_connectCompleter!.isCompleted) _connectCompleter!.completeError(e);
      rethrow;
    } finally {
      if (!_connectCompleter!.isCompleted) _connectCompleter!.complete();
    }
  }

  void _onConnectionLost() {
    if (_state != _ConnState.connected && _state != _ConnState.connecting) return;
    _logger.warning('Connection lost (state: $_state)');
    _state = _ConnState.reconnecting;
    _client = null;
    _cancelPing();
    _cleanupSocket();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();
    _reconnectAttempt++;
    final delay = min(pow(2, _reconnectAttempt).toInt(), _maxReconnectDelay);
    _logger.info('Scheduling reconnect attempt $_reconnectAttempt in ${delay}s');
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      if (_state != _ConnState.reconnecting) return;
      try {
        await connect();
      } catch (e) {
        _logger.error('Reconnect attempt $_reconnectAttempt failed: $e');
        _scheduleReconnect();
      }
    });
  }

  void _startPing() {
    _cancelPing();
    _pingTimer = Timer.periodic(_pingInterval, (_) async {
      if (_state != _ConnState.connected || _client == null) return;
      try {
        await _client!.invoke(const t.HelpGetConfig()).timeout(_pingTimeout);
      } catch (e) {
        _logger.warning('Ping failed: $e');
        _onConnectionLost();
      }
    });
  }

  void _cancelPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _cleanupSocket() async {
    if (_managedSocket != null) {
      await _managedSocket!.close();
      _managedSocket = null;
    }
  }

  @override
  Future<void> disconnect() async {
    _cancelPing();
    _cancelReconnectTimer();
    _state = _ConnState.disconnected;
    _client = null;
    _authorized = false;
    _reconnectAttempt = 0;
    await _cleanupSocket();
  }

  @override
  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  Future<void> _ensureConnected() async {
    if (_state == _ConnState.connected && _client != null) return;
    await connect();
  }

  @override
  Future<AuthResult> sendCode({required String phoneNumber, required int apiId, required String apiHash}) async {
    await _ensureConnected();
    try {
      final response = await _client!.auth.sendCode(
        apiId: apiId,
        apiHash: apiHash,
        phoneNumber: phoneNumber,
        settings: const t.CodeSettings(
          allowFlashcall: false,
          currentNumber: false,
          allowAppHash: true,
          allowMissedCall: false,
          allowFirebase: true,
          unknownNumber: false,
        ),
      ).timeout(const Duration(seconds: 20));

      if (response.error != null) return AuthError(response.error!.errorMessage);
      final result = response.result;
      if (result is t.AuthSentCode) {
        final typeStr = result.type.toString().split('.').last.replaceAll('AuthSentCodeType', '');
        _logger.info('Telegram sent code via: $typeStr');
        return AuthSuccess(result.phoneCodeHash, type: typeStr);
      }
      return const AuthError('Unexpected response');
    } catch (e) {
      _onConnectionLost();
      return AuthError('Failed: $e');
    }
  }

  @override
  Future<SignInResult> signIn({required String phoneNumber, required String phoneCodeHash, required String code}) async {
    await _ensureConnected();
    _lastPhoneNumber = phoneNumber;
    try {
      final response = await _client!.auth.signIn(
        phoneCodeHash: phoneCodeHash,
        phoneNumber: phoneNumber,
        phoneCode: code,
      );

      if (response.error != null) {
        if (response.error!.errorMessage.contains('SESSION_PASSWORD_NEEDED')) {
          final hint = await getAccountPasswordHint();
          return SignInPasswordRequired(hint ?? '');
        }
        return SignInError(response.error!.errorMessage);
      }

      _authorized = true;
      try {
        final meResult = await _client!.invoke(const t.UsersGetUsers(id: [t.InputUserSelf()])).timeout(const Duration(seconds: 15));
        if (meResult.result case final List users? when users.isNotEmpty) {
          final user = users.first as t.User;
          _myUserId = user.id;
          _myFirstName = user.firstName ?? '';
        }
      } catch (_) {}

      await _saveCurrentSession(phoneNumber, authKeyJson: _client?.authorizationKey != null ? jsonEncode(_client!.authorizationKey.toJson()) : null);
      return SignInSuccess(_myUserId ?? 0, _myFirstName ?? '');
    } catch (e) {
      _onConnectionLost();
      return SignInError('Sign in failed: $e');
    }
  }

  @override
  Future<bool> checkPassword({required String password}) async {
    await _ensureConnected();
    if (_accountPassword == null) return false;
    try {
      final pwd = await tg.check2FA(_accountPassword!, password);
      final response = await _client!.auth.checkPassword(password: pwd).timeout(const Duration(seconds: 15));
      if (response.error != null) return false;
      _authorized = true;
      try {
        final meResult = await _client!.invoke(const t.UsersGetUsers(id: [t.InputUserSelf()])).timeout(const Duration(seconds: 15));
        if (meResult.result case final List users? when users.isNotEmpty) {
          final user = users.first as t.User;
          _myUserId = user.id;
          _myFirstName = user.firstName ?? '';
        }
      } catch (_) {}
      await _saveCurrentSession(_lastPhoneNumber ?? '');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getAccountPasswordHint() async {
    if (!isConnected) return null;
    try {
      final response = await _client!.account.getPassword().timeout(const Duration(seconds: 15));
      if (response.error != null) return null;
      _accountPassword = response.result as t.AccountPassword;
      return _accountPassword!.hint;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int?> getMyUserId() async => _myUserId;
  @override
  Future<String?> getMyFirstName() async => _myFirstName;

  @override
  Future<List<TelegramGroup>> loadAllGroups() async {
    await _ensureConnected();
    _logger.info('loadAllGroups STARTED (Full retrieval)');
    final sw = Stopwatch()..start();

    final allGroupsMap = <int, TelegramGroup>{};
    
    await _fetchDialogsFromFolder(0, allGroupsMap);
    await _fetchDialogsFromFolder(1, allGroupsMap);

    final groups = allGroupsMap.values.toList();
    _logger.info('loadAllGroups FINISHED: ${groups.length} groups found in ${sw.elapsedMilliseconds}ms');
    return groups;
  }

  Future<void> _fetchDialogsFromFolder(int folderId, Map<int, TelegramGroup> targetMap) async {
    if (!isConnected) return;
    
    int offsetId = 0;
    t.InputPeerBase offsetPeer = const t.InputPeerEmpty();
    DateTime? offsetDate;
    bool hasMore = true;
    int page = 0;

    while (hasMore && page < 20) {
      page++;
      
      try {
        final response = await _client!.invoke(
          t.MessagesGetDialogs(
            excludePinned: false,
            offsetDate: offsetDate ?? DateTime.fromMillisecondsSinceEpoch(0),
            offsetId: offsetId,
            offsetPeer: offsetPeer,
            limit: 100,
            folderId: folderId,
            hash: 0,
          ),
        ).timeout(const Duration(seconds: 20));

        await Future.delayed(const Duration(milliseconds: 100));

        if (response.error != null) break;

        final result = response.result;
        List<dynamic> dialogList = [];
        List<dynamic> chatList = [];
        List<dynamic> messageList = [];
        List<dynamic> userList = [];

        if (result is t.MessagesDialogsSlice) {
          dialogList = result.dialogs;
          chatList = result.chats;
          messageList = result.messages;
          userList = result.users;
        } else if (result is t.MessagesDialogs) {
          dialogList = result.dialogs;
          chatList = result.chats;
          messageList = result.messages;
          userList = result.users;
        }

        if (dialogList.isEmpty) break;

        final chatMap = <int, dynamic>{};
        for (final chat in chatList) {
          if (chat is t.Chat) chatMap[chat.id] = chat;
          if (chat is t.Channel) chatMap[chat.id] = chat;
        }

        for (final dialog in dialogList) {
          if (dialog is! t.Dialog) continue;
          final peer = dialog.peer;

          int? chatId;
          ChatType type = ChatType.channel;
          int accessHash = 0;
          int memberCount = 0;

          if (peer is t.PeerChannel) {
            chatId = peer.channelId;
            final chat = chatMap[chatId];
            if (chat is t.Channel) {
              accessHash = chat.accessHash ?? 0;
              memberCount = chat.participantsCount ?? 0;
              type = chat.megagroup ? (chat.forum ? ChatType.forum : ChatType.supergroup) : ChatType.channel;
            }
          } else if (peer is t.PeerChat) {
            chatId = peer.chatId;
            type = ChatType.basicGroup;
            final chat = chatMap[chatId];
            if (chat is t.Chat) memberCount = chat.participantsCount;
          }

          if (chatId != null && !targetMap.containsKey(chatId)) {
            final title = _resolveTitle(chatList, chatId);
            if (title.isNotEmpty) {
              targetMap[chatId] = TelegramGroup(
                id: chatId,
                title: title,
                type: type,
                accessHash: accessHash,
                memberCount: memberCount,
              );
            }
          }
        }

        hasMore = dialogList.length >= 100;
        if (hasMore) {
          final lastDialog = dialogList.last as t.Dialog;
          offsetId = lastDialog.topMessage;
          final p = lastDialog.peer;
          
          if (p is t.PeerChannel) {
            offsetPeer = t.InputPeerChannel(channelId: p.channelId, accessHash: _resolveAccessHash(chatList, p.channelId));
          } else if (p is t.PeerChat) {
            offsetPeer = t.InputPeerChat(chatId: p.chatId);
          } else if (p is t.PeerUser) {
            int uHash = 0;
            for (final u in userList) {
              if (u is t.User && u.id == p.userId) {
                uHash = u.accessHash ?? 0;
                break;
              }
            }
            offsetPeer = t.InputPeerUser(userId: p.userId, accessHash: uHash);
          }

          for (final msg in messageList) {
            if ((msg is t.Message && msg.id == offsetId) || (msg is t.MessageService && msg.id == offsetId)) {
              offsetDate = (msg as dynamic).date;
              break;
            }
          }
        }
      } catch (e) {
        _logger.warning('Folder fetch error: $e');
        break;
      }
    }
  }

  @override
  Future<List<TelegramGroup>> searchPublicChats({required String query}) async {
    if (!isConnected) return [];
    try {
      final response = await _client!.invoke(
        t.ContactsSearch(
          q: query, 
          broadcasts: true,
          bots: false,
          limit: 50,
        ),
      ).timeout(const Duration(seconds: 15));
      if (response.error != null) return [];
      final result = response.result as t.ContactsFound;
      final results = <TelegramGroup>[];
      for (final peer in result.results) {
        int? chatId; ChatType type = ChatType.channel; int accessHash = 0;
        if (peer is t.PeerChannel) {
          chatId = peer.channelId; accessHash = _resolveAccessHash(result.chats, chatId);
        } else if (peer is t.PeerChat) {
          chatId = peer.chatId; type = ChatType.basicGroup;
        }
        if (chatId != null) {
          results.add(TelegramGroup(id: chatId, title: _resolveTitle(result.chats, chatId), type: type, accessHash: accessHash));
        }
      }
      return results;
    } catch (_) { return []; }
  }

  @override
  Future<SendMessageResult> sendMessage({required int chatId, required String text, required ChatType peerType, int? accessHash}) async {
    if (_state != _ConnState.connected || _client == null) {
      _logger.error('sendMessage: not connected (state: $_state)');
      return const SendMessageError('Not connected');
    }

    try {
      t.InputPeerBase peer;
      switch (peerType) {
        case ChatType.channel:
        case ChatType.forum:
        case ChatType.supergroup:
          peer = t.InputPeerChannel(channelId: chatId, accessHash: accessHash ?? 0);
          break;
        case ChatType.basicGroup:
          peer = t.InputPeerChat(chatId: chatId);
          break;
      }

      final response = await _client!.invoke(
        t.MessagesSendMessage(
          peer: peer,
          message: text,
          randomId: DateTime.now().millisecondsSinceEpoch,
          background: false,
          clearDraft: false,
          noforwards: false,
          silent: false,
          noWebpage: false,
          invertMedia: false,
          updateStickersetsOrder: false,
          allowPaidFloodskip: false,
        ),
      ).timeout(const Duration(seconds: 30));

      if (response.error != null) {
        final err = response.error!.errorMessage;
        if (err.contains('FLOOD_WAIT')) {
          return SendMessageFloodWait(int.tryParse(err.split('_').last) ?? 300);
        }
        if (err.contains('SLOWMODE_WAIT')) {
          return SendMessageSlowMode(int.tryParse(err.split('_').last) ?? 60);
        }
        return SendMessageError(err);
      }

      return const SendMessageSuccess(0);
    } catch (e) {
      _logger.error('sendMessage error: $e');
      _onConnectionLost();
      return SendMessageError('$e');
    }
  }

  @override
  Future<bool> editMessage({required int chatId, required int messageId, required String text}) async => false;
  @override
  Future<bool> deleteMessages({required int chatId, required List<int> messageIds}) async => false;
  @override
  Future<TelegramGroup?> getChat({required int chatId}) async => null;
  @override
  void onUpdates(void Function(Object update) callback) {}

  @override
  Future<void> loadSession() async {}
  @override
  Future<void> saveSession() async {}
  @override
  Future<void> clearSession() async {
    await _secureStorage.deleteSession();
    _authorized = false;
    _savedAuthKey = null;
  }

  @override
  Future<bool> hasSavedSession() async {
    final session = await _secureStorage.getSession();
    return !session.isEmpty;
  }

  Future<void> _saveCurrentSession(String phoneNumber, {String? authKeyJson}) async {
    final key = authKeyJson ?? (_client?.authorizationKey != null ? jsonEncode(_client!.authorizationKey.toJson()) : '');
    await _secureStorage.saveSession(SessionData(
      authorizationKey: key,
      phoneNumber: phoneNumber,
      userId: _myUserId ?? 0,
      firstName: _myFirstName ?? '',
    ));
  }

  Future<tg.AuthorizationKey?> _loadSession() async {
    // Try secure storage first
    try {
      final session = await _secureStorage.getSession();
      if (!session.isEmpty && session.authorizationKey.startsWith('{')) {
        return tg.AuthorizationKey.fromJson(jsonDecode(session.authorizationKey) as Map<String, dynamic>);
      }
    } catch (e) {
      _logger.error('Failed to load session from secure storage: $e');
    }
    return null;
  }

  String _resolveTitle(List<dynamic> chats, int chatId) {
    for (final chat in chats) {
      if (chat is t.Chat && chat.id == chatId) return chat.title;
      if (chat is t.Channel && chat.id == chatId) return chat.title;
    }
    return '';
  }

  int _resolveAccessHash(List<dynamic> chats, int chatId) {
    for (final chat in chats) {
      if (chat is t.Channel && chat.id == chatId) return chat.accessHash ?? 0;
    }
    return 0;
  }
}
