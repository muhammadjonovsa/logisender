import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Phone number input screen for Telegram authentication.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    debugPrint('[PhoneScreen] Send Code pressed');
    setState(() => _isLoading = true);

    final phone = Validators.normalizePhone(_phoneController.text.trim());
    await ref.read(authProvider.notifier).sendCode(phone);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      debugPrint('[PhoneScreen] AuthState updated: isLoading=${next.isLoading}, phoneCodeHash=${next.phoneCodeHash != null}');

      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (next.phoneCodeHash != null && !next.isLoading) {
        debugPrint('[PhoneScreen] SUCCESS: phoneCodeHash received, navigating to verifyCode');
        context.go(RouteNames.verifyCode);
      } else if (next.needs2FA && !next.isLoading) {
        debugPrint('[PhoneScreen] SUCCESS: 2FA required, navigating to twoFa');
        context.go(RouteNames.twoFa);
      }
    });

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
                  const AppLogo(size: 72, icon: Icons.phone_in_talk_rounded),
                  const SizedBox(height: 24),
                  const Text(
                    AppStrings.enterPhone,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.phoneSubtitle,
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
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\(\)\s]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: AppStrings.phoneNumber,
                              hintText: AppStrings.phoneHint,
                              prefixIcon: Icon(Icons.smartphone_rounded, color: AppColors.primary),
                            ),
                          ),
                          if (authState.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.error!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          AnimatedButton(
                            label: AppStrings.sendCode,
                            isLoading: _isLoading || authState.isLoading,
                            icon: Icons.send_rounded,
                            onPressed: _sendCode,
                          ),
                        ],
                      ),
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
}