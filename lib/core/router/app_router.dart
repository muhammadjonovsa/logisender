import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/router/route_names.dart';
import 'package:logisender/features/splash/splash_screen.dart';
import 'package:logisender/features/auth/presentation/api_config_screen.dart';
import 'package:logisender/features/auth/presentation/phone_screen.dart';
import 'package:logisender/features/auth/presentation/code_screen.dart';
import 'package:logisender/features/auth/presentation/two_fa_screen.dart';
import 'package:logisender/features/home/presentation/home_screen.dart';
import 'package:logisender/features/home/presentation/main_shell_screen.dart';
import 'package:logisender/features/groups/presentation/groups_screen.dart';
import 'package:logisender/features/templates/presentation/templates_screen.dart';
import 'package:logisender/features/statistics/presentation/statistics_screen.dart';
import 'package:logisender/features/settings/presentation/settings_screen.dart';
import 'package:logisender/features/templates/presentation/template_editor_screen.dart';
import 'package:logisender/features/automation/presentation/automation_screen.dart';

/// App router with GoRouter configuration.
class AppRouter extends ChangeNotifier {
  final Ref _ref;
  late final GoRouter _router;

  AppRouter(this._ref) {
    _router = GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: this,
      redirect: _redirect,
      routes: _routes,
    );
  }

  GoRouter get config => _router;

  /// Public method to trigger router refresh from outside
  void refresh() => notifyListeners();

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final isSplashFinished = _ref.read(splashFinishedProvider);
    
    final isAuthenticated = authState.isAuthenticated;
    final hasApiConfig = authState.hasApiConfig;
    final isLoading = authState.isLoading;

    final isSplashRoute = state.matchedLocation == RouteNames.splash;
    
    // While app is initializing auth state OR splash animation is running, stay on splash.
    if (isSplashRoute && (isLoading || !isSplashFinished)) {
      return null;
    }

    // After initialization and splash finished, handle redirects.
    if (!hasApiConfig) {
      return state.matchedLocation == RouteNames.apiConfig
          ? null
          : RouteNames.apiConfig;
    }

    if (!isAuthenticated) {
      final isAuthRoute = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.apiConfig ||
          state.matchedLocation == RouteNames.verifyCode ||
          state.matchedLocation == RouteNames.twoFa;

      if (isAuthRoute) return null;
      
      // If we were on splash and now auth finished, or if we tried to go home
      return RouteNames.login;
    }

    // If authenticated, don't allow auth screens or splash
    final isAuthRoute = state.matchedLocation == RouteNames.login ||
        state.matchedLocation == RouteNames.apiConfig ||
        state.matchedLocation == RouteNames.verifyCode ||
        state.matchedLocation == RouteNames.twoFa ||
        state.matchedLocation == RouteNames.splash;

    if (isAuthRoute) {
      return RouteNames.home;
    }

    return null;
  }

  List<RouteBase> get _routes => [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.apiConfig,
      builder: (context, state) => const ApiConfigScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const PhoneScreen(),
    ),
    GoRoute(
      path: RouteNames.verifyCode,
      builder: (context, state) => const CodeScreen(),
    ),
    GoRoute(
      path: RouteNames.twoFa,
      builder: (context, state) => const TwoFaScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          path: RouteNames.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.groups,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GroupsScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.templates,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TemplatesScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.statistics,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.templateEditor,
      builder: (context, state) => const TemplateEditorScreen(),
    ),
    GoRoute(
      path: RouteNames.automation,
      builder: (context, state) => const AutomationScreen(),
    ),
  ];
}
