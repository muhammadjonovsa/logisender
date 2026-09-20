import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logisender/core/router/route_names.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/utils/validators.dart';
import 'package:logisender/core/widgets/animated_button.dart';
import 'package:logisender/core/widgets/glass_card.dart';
import 'package:logisender/core/widgets/gradient_background.dart';
import 'package:logisender/features/templates/presentation/templates_provider.dart';

/// Template editor screen for creating new ad templates.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key});

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  bool _isSmart = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(templatesProvider.notifier).createTemplate(
          name: _nameController.text.trim(),
          text: _textController.text.trim(),
          isSmart: _isSmart,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (mounted) {
      context.go(RouteNames.templates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.newTemplate),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go(RouteNames.templates),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    AppStrings.templateName,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: Validators.validateTemplateName,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: AppStrings.templateNameHint,
                      prefixIcon: Icon(Icons.label_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppStrings.adContent,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _textController,
                    validator: (v) => Validators.validateRequired(v, 'Content'),
                    maxLines: 12,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: AppStrings.adContentHintFull,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        AppStrings.smartTemplate,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        AppStrings.autoVariationsSend,
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                      value: _isSmart,
                      onChanged: (v) => setState(() => _isSmart = v),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedButton(
                    label: AppStrings.saveTemplate,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
                    onPressed: _saveTemplate,
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