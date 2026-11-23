import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/module_section.dart';
import '../domain/study_module.dart';
import '../domain/study_module_repository.dart';
import 'module_section_json.dart';
import 'study_module_json.dart';

class SupabaseStudyModuleRepository implements StudyModuleRepository {
  const SupabaseStudyModuleRepository(
    this._client, {
    this.requestTimeout = const Duration(seconds: 10),
    this.retryCount = 2,
  });

  static const imagesBucket = 'module-covers';
  static const _studyModulesColumns =
      'id, slug, title, subtitle, area, topic_count, '
      'duration_in_minutes, resources, cover_image_path';
  static const _studyModuleDetailsColumns = 'module_id, description';
  static const _moduleSectionsColumns = 'id, title, summary, position';
  static const _contentBlocksColumns = 'section_id, position, kind, payload';

  final SupabaseClient _client;
  final Duration requestTimeout;
  final int retryCount;

  @override
  Future<List<StudyModule>> fetchPopular() =>
      _guard('carregar os módulos mais estudados', _fetchModules);

  @override
  Future<List<StudyModule>> fetchAll() =>
      _guard('carregar todos os módulos', _fetchModules);

  Future<List<StudyModule>> _fetchModules() async {
    final response = await _client
        .from('study_modules')
        .select(_studyModulesColumns)
        .order('popularity_rank', ascending: true)
        .retry(count: retryCount, requestTimeout: requestTimeout);
    final rows = response.cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final moduleIds = [for (final row in rows) row['id'] as String];
    final detailsResponse = await _client
        .from('study_module_details')
        .select(_studyModuleDetailsColumns)
        .inFilter('module_id', moduleIds)
        .retry(count: retryCount, requestTimeout: requestTimeout);
    final descriptions = <String, String>{
      for (final row in detailsResponse.cast<Map<String, dynamic>>())
        row['module_id'] as String: row['description'] as String,
    };

    return [
      for (final row in rows)
        StudyModuleJson.fromMap(
          row,
          description: descriptions[row['id']] ?? '',
          publicUrl: (path) =>
              _client.storage.from(imagesBucket).getPublicUrl(path),
        ),
    ];
  }

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) =>
      _guard('carregar as seções do módulo', () => _fetchSections(moduleId));

  Future<List<ModuleSection>> _fetchSections(String moduleId) async {
    final module = await _client
        .from('study_modules')
        .select('id')
        .eq('slug', moduleId)
        .maybeSingle()
        .retry(count: retryCount, requestTimeout: requestTimeout);
    if (module == null) return const [];

    final sectionResponse = await _client
        .from('module_sections')
        .select(_moduleSectionsColumns)
        .eq('module_id', module['id'] as String)
        .order('position', ascending: true)
        .retry(count: retryCount, requestTimeout: requestTimeout);
    final sectionRows = sectionResponse.cast<Map<String, dynamic>>();
    if (sectionRows.isEmpty) return const [];

    final sectionIds = [for (final row in sectionRows) row['id'] as String];
    final blockResponse = await _client
        .from('content_blocks')
        .select(_contentBlocksColumns)
        .inFilter('section_id', sectionIds)
        .order('position', ascending: true)
        .retry(count: retryCount, requestTimeout: requestTimeout);
    final blocksBySection = <String, List<Map<String, dynamic>>>{};
    for (final row in blockResponse.cast<Map<String, dynamic>>()) {
      final sectionId = row['section_id'] as String;
      blocksBySection.putIfAbsent(sectionId, () => []).add(row);
    }

    return moduleSectionsFromJson(sectionRows, blocksBySection);
  }

  Future<T> _guard<T>(String action, Future<T> Function() run) async {
    try {
      return await run();
    } on StudyModuleRepositoryException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Não foi possível $action: $error');
      Error.throwWithStackTrace(
        StudyModuleRepositoryException(
          'Não foi possível $action.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }
}
