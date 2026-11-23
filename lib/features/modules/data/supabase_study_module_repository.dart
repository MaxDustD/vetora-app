import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/content_block.dart';
import '../domain/module_section.dart';
import '../domain/study_module.dart';
import '../domain/study_module_repository.dart';
import 'content_block_codec.dart';
import 'study_module_json.dart';

class SupabaseStudyModuleRepository implements StudyModuleRepository {
  const SupabaseStudyModuleRepository(this.client);

  static const _coverBucket = 'module-covers';

  final SupabaseClient client;

  @override
  Future<List<StudyModule>> fetchPopular() => _fetchModules();

  @override
  Future<List<StudyModule>> fetchAll() => _fetchModules();

  Future<List<StudyModule>> _fetchModules() async {
    final response = await client
        .from('study_modules')
        .select(
          'id, slug, title, subtitle, area, topic_count, '
          'duration_in_minutes, resources, cover_image_path',
        )
        .order('popularity_rank');
    final rows = response.cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final moduleIds = [for (final row in rows) row['id'] as String];
    final detailsResponse = await client
        .from('study_module_details')
        .select('module_id, description')
        .inFilter('module_id', moduleIds);
    final descriptions = <String, String>{
      for (final row in detailsResponse.cast<Map<String, dynamic>>())
        row['module_id'] as String: row['description'] as String,
    };

    return [
      for (final row in rows)
        StudyModuleJson.fromMap(
          row,
          description: descriptions[row['id']] ?? '',
          coverImageUrl: _coverImageUrl(row['cover_image_path'] as String?),
        ),
    ];
  }

  String? _coverImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return client.storage.from(_coverBucket).getPublicUrl(path);
  }

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) async {
    final module = await client
        .from('study_modules')
        .select('id')
        .eq('slug', moduleId)
        .maybeSingle();
    if (module == null) return const [];

    final sectionResponse = await client
        .from('module_sections')
        .select('id, title, summary')
        .eq('module_id', module['id'] as String)
        .order('position');
    final sectionRows = sectionResponse.cast<Map<String, dynamic>>();
    if (sectionRows.isEmpty) return const [];

    final sectionIds = [for (final row in sectionRows) row['id'] as String];
    final blockResponse = await client
        .from('content_blocks')
        .select('section_id, kind, payload')
        .inFilter('section_id', sectionIds)
        .order('position');
    final blocksBySection = <String, List<ContentBlock>>{};
    for (final row in blockResponse.cast<Map<String, dynamic>>()) {
      final sectionId = row['section_id'] as String;
      final payload = (row['payload'] as Map).cast<String, Object?>();
      blocksBySection
          .putIfAbsent(sectionId, () => [])
          .add(ContentBlockCodec.decode(row['kind'] as String, payload));
    }

    return [
      for (final row in sectionRows)
        ModuleSection(
          id: row['id'] as String,
          title: row['title'] as String,
          summary: row['summary'] as String,
          blocks: List.unmodifiable(
            blocksBySection[row['id']] ?? const <ContentBlock>[],
          ),
        ),
    ];
  }
}
