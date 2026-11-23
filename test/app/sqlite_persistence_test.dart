import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vetora/app/database/vetora_database.dart';
import 'package:vetora/features/favorites/data/favorites_storage.dart';
import 'package:vetora/features/favorites/data/sqlite_favorites_storage.dart';
import 'package:vetora/features/modules/data/fake_module_content.dart';
import 'package:vetora/features/modules/data/fake_study_module_repository.dart';
import 'package:vetora/features/modules/data/sqlite_study_module_repository.dart';
import 'package:vetora/features/modules/domain/content_block.dart';

/// Persistência em SQLite, com o banco em memória via FFI (sem emulador).
void main() {
  sqfliteFfiInit();
  late Database db;

  setUp(() async {
    db = await VetoraDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => db.close());

  group('SqliteStudyModuleRepository', () {
    test('devolve o catálogo semeado, na ordem de popularidade', () async {
      final modules = await SqliteStudyModuleRepository(db).fetchPopular();
      const expected = FakeStudyModuleRepository.modules;

      expect(modules.map((m) => m.id), expected.map((m) => m.id));
      for (final (i, module) in modules.indexed) {
        expect(module.title, expected[i].title);
        expect(module.subtitle, expected[i].subtitle);
        expect(module.area, expected[i].area);
        expect(module.topicCount, expected[i].topicCount);
        expect(module.durationInMinutes, expected[i].durationInMinutes);
        expect(module.resources, expected[i].resources);
        expect(module.description, expected[i].description);
      }
    });

    test('reconstrói seções e blocos de todos os tipos', () async {
      final sections = await SqliteStudyModuleRepository(db)
          .fetchSections('calculo-1');
      final expected = fakeModuleContent['calculo-1']!;

      expect(sections.map((s) => s.id), expected.map((s) => s.id));
      final first = sections.first;
      expect(first.blocks, hasLength(expected.first.blocks.length));
      expect(
        (first.blocks[0] as ParagraphBlock).text,
        (expected.first.blocks[0] as ParagraphBlock).text,
      );
      final formula = first.blocks[1] as FormulaBlock;
      expect(formula.caption, 'Notação de função');
      expect((first.blocks[3] as KeyPointsBlock).items, hasLength(4));
      final example = first.blocks.whereType<ExampleBlock>().first;
      expect(example.answer, 'D(f) = [2, 5) ∪ (5, +∞)');
    });

    test('módulo sem material devolve lista vazia', () async {
      expect(
        await SqliteStudyModuleRepository(db).fetchSections('termodinamica'),
        isEmpty,
      );
    });

    test('CHECK recusa área fora da lista', () async {
      expect(
        () => db.insert('study_modules', {
          'id': 'x',
          'title': 'X',
          'area': 'quimica',
          'topic_count': 1,
          'duration_in_minutes': 10,
          'popularity_rank': 99,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('apagar um módulo apaga seções e blocos (cascade)', () async {
      await db.delete(
        'study_modules',
        where: 'id = ?',
        whereArgs: ['calculo-1'],
      );
      final blocks = await db.query(
        'content_blocks',
        where: 'module_id = ?',
        whereArgs: ['calculo-1'],
      );
      expect(blocks, isEmpty);
    });
  });

  group('SqliteFavoritesStorage', () {
    test('grava e lê os favoritos na ordem', () async {
      final storage = SqliteFavoritesStorage(db);
      expect(await storage.load(), isEmpty);

      await storage.save(['termodinamica', 'calculo-1']);
      expect(await storage.load(), ['termodinamica', 'calculo-1']);

      await storage.save(['calculo-1']);
      expect(await storage.load(), ['calculo-1']);
    });

    test(
      'falha ao gravar id inexistente sem perder a lista anterior',
      () async {
        final storage = SqliteFavoritesStorage(db);
        await storage.save(['calculo-1']);

        await expectLater(
          storage.save(['nao-existe', 'calculo-1']),
          throwsA(isA<DatabaseException>()),
        );
        expect(await storage.load(), ['calculo-1']);
      },
    );

    test(
      'importa os favoritos antigos do shared_preferences uma vez',
      () async {
        SharedPreferences.setMockInitialValues({
          FavoritesStorage.favoritesKey: [
            'circuitos-eletricos',
            'fisica-do-movimento', // módulo que não existe mais
          ],
        });
        final storage = SqliteFavoritesStorage(db);

        await storage.importLegacy(const FavoritesStorage());

        expect(await storage.load(), ['circuitos-eletricos']);
        expect(await const FavoritesStorage().load(), isEmpty);
      },
    );
  });
}
