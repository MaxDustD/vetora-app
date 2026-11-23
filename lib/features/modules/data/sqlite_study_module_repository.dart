import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/content_block.dart';
import '../domain/module_section.dart';
import '../domain/study_module.dart';
import '../domain/study_module_repository.dart';
import 'content_block_codec.dart';
import 'module_storage_keys.dart';

/// [StudyModuleRepository] que lê o catálogo do banco SQLite local
/// (`VetoraDatabase`).
///
/// As telas não mudam: dependem só do contrato, e a troca da implementação
/// falsa por esta acontece na raiz de composição (`main.dart`).
class SqliteStudyModuleRepository implements StudyModuleRepository {
  const SqliteStudyModuleRepository(this.db);

  final Database db;

  @override
  Future<List<StudyModule>> fetchPopular() => _fetchModules();

  @override
  Future<List<StudyModule>> fetchAll() => _fetchModules();

  Future<List<StudyModule>> _fetchModules() async {
    final rows = await db.query('study_modules', orderBy: 'popularity_rank');
    return [for (final row in rows) _moduleFrom(row)];
  }

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) async {
    final sectionRows = await db.query(
      'module_sections',
      where: 'module_id = ?',
      whereArgs: [moduleId],
      orderBy: 'position',
    );
    if (sectionRows.isEmpty) return const [];

    // Uma consulta só para todos os blocos do módulo, agrupados em memória.
    final blockRows = await db.query(
      'content_blocks',
      where: 'module_id = ?',
      whereArgs: [moduleId],
      orderBy: 'section_id, position',
    );
    final blocksBySection = <String, List<ContentBlock>>{};
    for (final row in blockRows) {
      blocksBySection
          .putIfAbsent(row['section_id']! as String, () => [])
          .add(
            ContentBlockCodec.decode(
              row['type']! as String,
              (jsonDecode(row['payload']! as String) as Map)
                  .cast<String, Object?>(),
            ),
          );
    }

    return [
      for (final row in sectionRows)
        ModuleSection(
          id: row['id']! as String,
          title: row['title']! as String,
          summary: row['summary']! as String,
          blocks: List.unmodifiable(blocksBySection[row['id']] ?? const []),
        ),
    ];
  }

  static StudyModule _moduleFrom(Map<String, Object?> row) {
    final resources = (jsonDecode(row['resources']! as String) as List)
        .cast<String>()
        .map(ModuleStorageKeys.resourceFrom);
    return StudyModule(
      id: row['id']! as String,
      title: row['title']! as String,
      subtitle: row['subtitle']! as String,
      area: ModuleStorageKeys.areaFrom(row['area']! as String),
      topicCount: row['topic_count']! as int,
      durationInMinutes: row['duration_in_minutes']! as int,
      resources: Set.unmodifiable(resources),
      description: row['description']! as String,
    );
  }
}
