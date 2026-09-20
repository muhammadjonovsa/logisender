import 'package:logisender/core/constants/app_constants.dart';
import 'package:logisender/core/storage/hive_storage_service.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/utils/logger_service.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing ad templates.
class TemplateRepository {
  final HiveStorageService _hiveStorage;
  final LoggerService _logger;
  static const _uuid = Uuid();

  TemplateRepository({
    required HiveStorageService hiveStorage,
    required LoggerService logger,
  })  : _hiveStorage = hiveStorage,
        _logger = logger;

  Future<List<AdTemplate>> loadTemplates() async {
    try {
      final data = await _hiveStorage.getAll(AppConstants.templatesBox);
      final templates = data
          .whereType<Map>()
          .map((e) => AdTemplate.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _logger.info('Loaded ${templates.length} templates');
      return templates;
    } catch (e) {
      _logger.error('Failed to load templates: $e', e);
      return [];
    }
  }

  Future<AdTemplate> createTemplate({
    required String name,
    required String text,
    String? photoUrl,
    String? documentUrl,
    String? videoUrl,
    String? title,
    bool isSmart = true,
  }) async {
    final now = DateTime.now();
    final template = AdTemplate(
      id: _uuid.v4(),
      name: name,
      text: text,
      photoUrl: photoUrl,
      documentUrl: documentUrl,
      videoUrl: videoUrl,
      title: title,
      isSmart: isSmart,
      createdAt: now,
      updatedAt: now,
    );

    await _hiveStorage.put(
      AppConstants.templatesBox,
      template.id,
      template.toJson(),
    );

    _logger.info('Created template: ${template.name}');
    return template;
  }

  Future<AdTemplate> updateTemplate(AdTemplate template) async {
    final updated = template.copyWith(updatedAt: DateTime.now());
    await _hiveStorage.put(
      AppConstants.templatesBox,
      updated.id,
      updated.toJson(),
    );
    _logger.info('Updated template: ${updated.name}');
    return updated;
  }

  Future<void> deleteTemplate(String templateId) async {
    await _hiveStorage.delete(AppConstants.templatesBox, templateId);
    _logger.info('Deleted template: $templateId');
  }

  Future<AdTemplate> duplicateTemplate(AdTemplate source) async {
    return createTemplate(
      name: '${source.name} (Copy)',
      text: source.text,
      photoUrl: source.photoUrl,
      documentUrl: source.documentUrl,
      videoUrl: source.videoUrl,
      title: source.title,
      isSmart: source.isSmart,
    );
  }
}
