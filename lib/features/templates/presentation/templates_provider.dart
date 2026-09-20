import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logisender/core/di/providers.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/features/templates/data/template_repository.dart';

class TemplatesState {
  final List<AdTemplate> templates;
  final AdTemplate? selectedTemplate;
  final bool isLoading;

  const TemplatesState({
    this.templates = const [],
    this.selectedTemplate,
    this.isLoading = false,
  });

  TemplatesState copyWith({
    List<AdTemplate>? templates,
    AdTemplate? selectedTemplate,
    bool clearSelected = false,
    bool? isLoading,
  }) {
    return TemplatesState(
      templates: templates ?? this.templates,
      selectedTemplate: clearSelected ? null : (selectedTemplate ?? this.selectedTemplate),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TemplatesNotifier extends StateNotifier<TemplatesState> {
  final TemplateRepository _repository;

  TemplatesNotifier(this._repository) : super(const TemplatesState());

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true);
    try {
      final templates = await _repository.loadTemplates();
      if (!mounted) return;
      
      AdTemplate? newSelected = state.selectedTemplate;
      if (newSelected != null) {
        // Update selected template if it still exists
        try {
          newSelected = templates.firstWhere((t) => t.id == newSelected!.id);
        } catch (_) {
          newSelected = null;
        }
      }
      
      // Select first by default if nothing selected
      if (newSelected == null && templates.isNotEmpty) {
        newSelected = templates.first;
      }

      state = state.copyWith(
        templates: templates,
        selectedTemplate: newSelected,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[TemplatesNotifier] loadTemplates ERROR: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void selectTemplate(AdTemplate template) {
    state = state.copyWith(selectedTemplate: template);
  }

  Future<void> createTemplate({
    required String name,
    required String text,
    String? title,
    bool isSmart = true,
  }) async {
    try {
      await _repository.createTemplate(name: name, text: text, title: title, isSmart: isSmart);
      if (!mounted) return;
      await loadTemplates();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      debugPrint('[TemplatesNotifier] createTemplate ERROR: $e');
    }
  }

  Future<void> updateTemplate(AdTemplate template) async {
    try {
      await _repository.updateTemplate(template);
      if (!mounted) return;
      await loadTemplates();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      debugPrint('[TemplatesNotifier] updateTemplate ERROR: $e');
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await _repository.deleteTemplate(templateId);
      if (!mounted) return;
      await loadTemplates();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      debugPrint('[TemplatesNotifier] deleteTemplate ERROR: $e');
    }
  }

  Future<void> duplicateTemplate(AdTemplate template) async {
    try {
      await _repository.duplicateTemplate(template);
      if (!mounted) return;
      await loadTemplates();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      debugPrint('[TemplatesNotifier] duplicateTemplate ERROR: $e');
    }
  }
}

final templatesProvider =
    StateNotifierProvider<TemplatesNotifier, TemplatesState>((ref) {
  return TemplatesNotifier(ref.watch(templateRepositoryProvider));
});
