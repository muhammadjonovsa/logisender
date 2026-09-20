import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/router/route_names.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/utils/validators.dart';
import 'package:logisender/core/widgets/animated_button.dart';
import 'package:logisender/core/widgets/app_logo.dart';
import 'package:logisender/core/widgets/glass_card.dart';
import 'package:logisender/core/widgets/gradient_background.dart';
import 'package:url_launcher/url_launcher.dart';

/// API configuration screen for entering Telegram API ID and Hash.
class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiIdController = TextEditingController();
  final _apiHashController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _apiIdController.dispose();
    _apiHashController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    debugPrint('[ApiConfigScreen] Connect pressed');
    setState(() => _isLoading = true);

    final apiId = int.tryParse(_apiIdController.text.trim());
    if (apiId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API ID raqam bo\'lishi kerak'), backgroundColor: AppColors.error),
      );
      return;
    }
    final apiHash = _apiHashController.text.trim();

    try {
      await ref.read(authProvider.notifier).saveApiConfig(apiId, apiHash);
    } catch (e) {
      debugPrint('[ApiConfigScreen] saveApiConfig error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    debugPrint('[ApiConfigScreen] After save: hasApiConfig=${authState.hasApiConfig}, error=${authState.error}');

    if (authState.error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    if (mounted) {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 72),
                  const SizedBox(height: 24),
                  const Text(
                    AppStrings.apiSetup,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.apiSetupSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _apiIdController,
                            keyboardType: TextInputType.number,
                            validator: Validators.validateApiId,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: AppStrings.apiId,
                              hintText: '12345678',
                              prefixIcon: Icon(Icons.key_rounded, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _apiHashController,
                            validator: Validators.validateApiHash,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: AppStrings.apiHash,
                              hintText: 'a1b2c3d4e5f6...',
                              prefixIcon: Icon(Icons.lock_rounded, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedButton(
                            label: AppStrings.connect,
                            isLoading: _isLoading,
                            icon: Icons.wifi_rounded,
                            onPressed: _saveConfig,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _openTelegramApi(),
                    child: const Text(
                      AppStrings.getApiCredentials,
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTelegramApi() async {
    final uri = Uri.parse('https://my.telegram.org');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}