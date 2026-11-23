import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/modules/data/content_block_codec.dart';
import '../../features/modules/data/fake_module_content.dart';
import '../../features/modules/data/fake_study_module_repository.dart';
import '../../features/modules/data/module_storage_keys.dart';
import '../../features/modules/domain/module_section.dart';
import '../../features/modules/domain/study_module.dart';

/// Banco SQLite local do Vetora: o catálogo de módulos, o material de estudo
/// e os favoritos.
///
/// Fica na camada `app` porque é infraestrutura compartilhada por várias
/// features. Perfil e primeiro acesso continuam no `shared_preferences`:
/// são poucos valores soltos, sem relação entre si.
///
/// Na primeira abertura as tabelas são criadas e preenchidas com o catálogo
/// de demonstração; nas seguintes, os dados gravados são reaproveitados.
abstract final class VetoraDatabase {
  static const fileName = 'vetora.db';

  /// Suba este número (e trate em `onUpgrade`) ao mudar o esquema.
  static const version = 2;

  /// Abre (ou cria) o banco.
  ///
  /// [factory] e [path] existem para os testes, que usam o SQLite via FFI e
  /// `inMemoryDatabasePath`.
  static Future<Database> open({
    DatabaseFactory? factory,
    String? path,
    List<StudyModule> seedModules = FakeStudyModuleRepository.modules,
    Map<String, List<ModuleSection>> seedSections = fakeModuleContent,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);

    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        // O SQLite vem com chaves estrangeiras desligadas: sem isto, o
        // ON DELETE CASCADE não funcionaria.
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await createSchema(db);
          await seed(db, seedModules, seedSections);
        },
        onUpgrade: (db, oldVersion, _) async {
          if (oldVersion < 2) await _removeFavoritesCatalogForeignKey(db);
        },
      ),
    );
  }

  static Future<void> _removeFavoritesCatalogForeignKey(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE favorites_v2 (
        module_id TEXT    PRIMARY KEY,
        position  INTEGER NOT NULL
      )''');
    await db.execute('''
      INSERT INTO favorites_v2 (module_id, position)
      SELECT module_id, position FROM favorites''');
    await db.execute('DROP TABLE favorites');
    await db.execute('ALTER TABLE favorites_v2 RENAME TO favorites');
  }

  static Future<void> createSchema(DatabaseExecutor db) async {
    final areas = ModuleStorageKeys.sqlList(ModuleStorageKeys.areas.values);
    final blockTypes = ModuleStorageKeys.sqlList(ContentBlockCodec.types);

    await db.execute('''
      CREATE TABLE study_modules (
        id                  TEXT    PRIMARY KEY,
        title               TEXT    NOT NULL CHECK (length(trim(title)) > 0),
        subtitle            TEXT    NOT NULL DEFAULT '',
        area                TEXT    NOT NULL CHECK (area IN ($areas)),
        topic_count         INTEGER NOT NULL CHECK (topic_count >= 0),
        duration_in_minutes INTEGER NOT NULL CHECK (duration_in_minutes > 0),
        resources           TEXT    NOT NULL DEFAULT '[]',
        description         TEXT    NOT NULL DEFAULT '',
        popularity_rank     INTEGER NOT NULL UNIQUE
      )''');

    await db.execute('''
      CREATE TABLE module_sections (
        module_id TEXT    NOT NULL
                  REFERENCES study_modules (id) ON DELETE CASCADE,
        id        TEXT    NOT NULL,
        position  INTEGER NOT NULL CHECK (position >= 0),
        title     TEXT    NOT NULL,
        summary   TEXT    NOT NULL DEFAULT '',
        PRIMARY KEY (module_id, id),
        UNIQUE (module_id, position)
      )''');

    await db.execute('''
      CREATE TABLE content_blocks (
        module_id  TEXT    NOT NULL,
        section_id TEXT    NOT NULL,
        position   INTEGER NOT NULL CHECK (position >= 0),
        type       TEXT    NOT NULL CHECK (type IN ($blockTypes)),
        payload    TEXT    NOT NULL CHECK (json_valid(payload)),
        PRIMARY KEY (module_id, section_id, position),
        FOREIGN KEY (module_id, section_id)
          REFERENCES module_sections (module_id, id) ON DELETE CASCADE
      )''');

    // A ordem dos favoritos (mais recente primeiro) é guardada em position.
    await db.execute('''
      CREATE TABLE favorites (
        module_id TEXT    PRIMARY KEY,
        position  INTEGER NOT NULL
      )''');
  }

  /// Grava o catálogo inicial. A ordem de [modules] vira o ranking de
  /// popularidade usado em `fetchPopular`.
  static Future<void> seed(
    DatabaseExecutor db,
    List<StudyModule> modules,
    Map<String, List<ModuleSection>> sections,
  ) async {
    final batch = db.batch();
    for (final (rank, module) in modules.indexed) {
      batch.insert('study_modules', {
        'id': module.id,
        'title': module.title,
        'subtitle': module.subtitle,
        'area': ModuleStorageKeys.areas[module.area],
        'topic_count': module.topicCount,
        'duration_in_minutes': module.durationInMinutes,
        'resources': jsonEncode([
          for (final r in module.resources) ModuleStorageKeys.resources[r],
        ]),
        'description': module.description,
        'popularity_rank': rank,
      });

      for (final (position, section)
          in (sections[module.id] ?? const <ModuleSection>[]).indexed) {
        batch.insert('module_sections', {
          'module_id': module.id,
          'id': section.id,
          'position': position,
          'title': section.title,
          'summary': section.summary,
        });
        for (final (blockPosition, block) in section.blocks.indexed) {
          batch.insert('content_blocks', {
            'module_id': module.id,
            'section_id': section.id,
            'position': blockPosition,
            'type': ContentBlockCodec.typeOf(block),
            'payload': jsonEncode(ContentBlockCodec.payloadOf(block)),
          });
        }
      }
    }
    await batch.commit(noResult: true);
  }
}
