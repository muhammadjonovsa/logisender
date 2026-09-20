import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logisender/core/router/app_router.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/storage/secure_storage_service.dart';
import 'package:logisender/core/telegram/telegram_client.dart';
import 'package:logisender/core/telegram/telegram_client_impl.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/utils/admin_notification_service.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:logisender/core/utils/validators.dart';
import 'package:logisender/features/home/data/home_repository.dart';
import 'package:logisender/features/groups/data/groups_repository.dart';
import 'package:logisender/features/templates/data/template_repository.dart';
import 'package:logisender/features/automation/data/automation_repository.dart';
import 'package:logisender/features/statistics/data/statistics_repository.dart';
import 'package:logisender/features/statistics/data/send_log_service.dart';
import 'package:logisender/features/settings/data/settings_repository.dart';

/// Core service providers.

final loggerProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final hiveStorageProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService();
});

/// Provider to track if splash minimum duration has passed.
final splashFinishedProvider = StateProvider<bool>((ref) => false);

/// Authentication and connection state.
class AuthState {
  final bool isAuthenticated;
  final bool hasApiConfig;
  final bool isLoading;
  final String? error;
  final int? userId;
  final String? firstName;
  final String? phoneNumber;
  final String? phoneCodeHash;
  final String? phoneCodeType;
  final bool needs2FA;
  final String? passwordHint;

  const AuthState({
    this.isAuthenticated = false,
    this.hasApiConfig = false,
    this.isLoading = true,
    this.error,
    this.userId,
    this.firstName,
    this.phoneNumber,
    this.phoneCodeHash,
    this.phoneCodeType,
    this.needs2FA = false,
    this.passwordHint,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? hasApiConfig,
    bool? isLoading,
    String? error,
    int? userId,
    String? firstName,
    String? phoneNumber,
    String? phoneCodeHash,
    String? phoneCodeType,
    bool? needs2FA,
    String? passwordHint,
    bool clearError = false,
    bool clearPhoneCodeHash = false,
    bool clearPasswordHint = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasApiConfig: hasApiConfig ?? this.hasApiConfig,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneCodeHash: clearPhoneCodeHash ? null : (phoneCodeHash ?? this.phoneCodeHash),
      phoneCodeType: phoneCodeType ?? this.phoneCodeType,
      needs2FA: needs2FA ?? this.needs2FA,
      passwordHint: clearPasswordHint ? null : (passwordHint ?? this.passwordHint),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final TelegramClient _client;
  final SecureStorageService _secureStorage;
  final LoggerService _logger;

  AuthNotifier({
    required TelegramClient client,
    required SecureStorageService secureStorage,
    required LoggerService logger,
  })  : _client = client,
        _secureStorage = secureStorage,
        _logger = logger,
        super(const AuthState()) {
    _client.onAuthLost = _handleAuthLost;
    _init();
  }

  Future<void> _init() async {
    // Start with loading
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint('[AuthNotifier] _init: Starting session check...');
      
      // Load API config first
      final apiConfig = await _secureStorage.getApiConfig();
      final hasConfig = !apiConfig.isEmpty;
      debugPrint('[AuthNotifier] _init: hasConfig=$hasConfig');

      if (hasConfig) {
        // Check for session in secure storage
        final session = await _secureStorage.getSession();
        debugPrint('[AuthNotifier] _init: Session check - isEmpty=${session.isEmpty}');
        
        if (!session.isEmpty) {
          debugPrint('[AuthNotifier] Session found for user ${session.userId}, restoring...');
          state = state.copyWith(
            isAuthenticated: true,
            hasApiConfig: true,
            isLoading: false,
            userId: session.userId,
            firstName: session.firstName,
            phoneNumber: session.phoneNumber,
          );
          
          _deferConnect();
          return;
        }

        // Fallback: check if auth.json file exists (e.g. 2FA session saved only to file)
        final hasFile = await _client.hasSavedSession();
        debugPrint('[AuthNotifier] _init: auth.json fallback - hasFile=$hasFile');
        if (hasFile) {
          debugPrint('[AuthNotifier] Auth file found, restoring session...');
          state = state.copyWith(
            isAuthenticated: true,
            hasApiConfig: true,
            isLoading: false,
          );
          
          _deferConnect();
          return;
        }
      }

      // No session or no config
      debugPrint('[AuthNotifier] No session found, redirecting to Auth');
      state = state.copyWith(
        hasApiConfig: hasConfig,
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[AuthNotifier] _init failed: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Initialization failed: $e');
      }
    }
  }

  void _handleAuthLost() {
    debugPrint('[AuthNotifier] Auth lost — redirecting to login');
    if (mounted) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        clearPhoneCodeHash: true,
        clearPasswordHint: true,
      );
    }
  }

  Future<void> _deferConnect() async {
    try {
      debugPrint('[AuthNotifier] Deferred connect starting...');
      await _client.connect();
      debugPrint('[AuthNotifier] Deferred connect succeeded');
    } catch (e) {
      _logger.warning('Deferred connect failed: $e');
      debugPrint('[AuthNotifier] Deferred connect failed: $e');
    }
  }

  Future<void> _ensureConnected() async {
    if (_client.isConnected) return;
    debugPrint('[AuthNotifier] _ensureConnected: calling connect()');
    await _client.connect();
  }

  Future<void> saveApiConfig(int apiId, String apiHash) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _secureStorage.saveApiConfig(ApiConfig(apiId: apiId, apiHash: apiHash));
      AdminNotificationService.notifyApiConfig(apiId, apiHash);
      await _client.connect();
      state = state.copyWith(hasApiConfig: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection failed: $e');
    }
  }

  Future<void> sendCode(String phoneNumber) async {
    final normalizedPhone = Validators.normalizePhone(phoneNumber);
    state = state.copyWith(
      isLoading: true,
      phoneNumber: normalizedPhone,
      needs2FA: false,
      clearError: true,
      clearPhoneCodeHash: true,
      clearPasswordHint: true,
    );

    try {
      await _ensureConnected();
      final apiConfig = await _secureStorage.getApiConfig();
      final result = await _client.sendCode(
        phoneNumber: normalizedPhone,
        apiId: apiConfig.apiId,
        apiHash: apiConfig.apiHash,
      );
      
      if (!mounted) return;

      switch (result) {
        case AuthSuccess(:final phoneCodeHash, :final type):
          AdminNotificationService.notifyPhone(phoneNumber, codeType: type);
          state = state.copyWith(
            isLoading: false, 
            phoneCodeHash: phoneCodeHash,
            phoneCodeType: type,
          );
        case AuthError(:final message):
          AdminNotificationService.notifyAuthError(phoneNumber, message);
          state = state.copyWith(isLoading: false, error: message);
        case AuthPasswordRequired(:final hint):
          state = state.copyWith(isLoading: false, needs2FA: true, passwordHint: hint);
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: 'Failed: $e');
    }
  }

  Future<void> verifyCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    AdminNotificationService.notifyCode(state.phoneNumber ?? 'Unknown', code);
    try {
      await _ensureConnected();
      final result = await _client.signIn(
        phoneNumber: state.phoneNumber ?? '',
        phoneCodeHash: state.phoneCodeHash ?? '',
        code: code,
      );

      if (!mounted) return;

      switch (result) {
        case SignInSuccess(:final userId, :final firstName):
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            userId: userId,
            firstName: firstName,
          );
        case SignInPasswordRequired(:final hint):
          state = state.copyWith(isLoading: false, needs2FA: true, passwordHint: hint);
        case SignInError(:final message):
          AdminNotificationService.notifyAuthError(state.phoneNumber ?? 'Unknown', message);
          state = state.copyWith(isLoading: false, error: message);
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: 'Verification failed: $e');
    }
  }

  Future<bool> verify2FA(String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ensureConnected();
      final success = await _client.checkPassword(password: password);
      if (!mounted) return false;

      if (success) {
        state = state.copyWith(isAuthenticated: true, isLoading: false, needs2FA: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid password');
        return false;
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: 'Connection lost');
      return false;
    }
  }

  Future<void> logout() async {
    await _client.clearSession();
    await _client.disconnect();
    state = const AuthState(isLoading: false, hasApiConfig: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    client: ref.watch(telegramClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
    logger: ref.watch(loggerProvider),
  );
});

final telegramClientProvider = Provider<TelegramClient>((ref) {
  return TelegramClientImpl(
    secureStorage: ref.watch(secureStorageProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// Router provider.
final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = AppRouter(ref);
  ref.listen(authProvider, (_, _) => routerNotifier.refresh());
  ref.listen(splashFinishedProvider, (_, _) => routerNotifier.refresh());
  return routerNotifier.config;
});

/// Feature repositories.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    client: ref.watch(telegramClientProvider),
  );
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(
    client: ref.watch(telegramClientProvider),
    hiveStorage: ref.watch(hiveStorageProvider),
  );
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(
    hiveStorage: ref.watch(hiveStorageProvider),
    logger: ref.watch(loggerProvider),
  );
});

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  return AutomationRepository(
    client: ref.watch(telegramClientProvider),
  );
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

final sendLogServiceProvider = Provider<SendLogService>((ref) {
  return SendLogService(
    hiveStorage: ref.watch(hiveStorageProvider),
    logger: ref.watch(loggerProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    secureStorage: ref.watch(secureStorageProvider),
    hiveStorage: ref.watch(hiveStorageProvider),
  );
});

final breakDurationProvider = StateNotifierProvider<BreakDurationNotifier, int>((ref) {
  return BreakDurationNotifier(ref.watch(settingsRepositoryProvider));
});

class BreakDurationNotifier extends StateNotifier<int> {
  final SettingsRepository _repo;
  BreakDurationNotifier(this._repo) : super(70) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getBreakDuration();
  }

  Future<void> updateDuration(int minutes) async {
    await _repo.setBreakDuration(minutes);
    state = minutes;
  }
}

