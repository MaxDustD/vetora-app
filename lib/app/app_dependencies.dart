import 'package:flutter/foundation.dart';

import '../features/favorites/data/favorites_storage.dart';
import '../features/favorites/data/sqlite_favorites_storage.dart';
import '../features/modules/data/fake_study_module_repository.dart';
import '../features/modules/data/sqlite_study_module_repository.dart';
import '../features/modules/domain/study_module_repository.dart';
import 'database/platform_database_factory.dart';
import 'database/vetora_database.dart';

/// Implementações concretas escolhidas na inicialização do app.
///
/// O padrão (`const AppDependencies()`) é o de demonstração, usado pelos
/// testes de widget; [load] troca pelas versões persistidas em SQLite.
class AppDependencies {
  const AppDependencies({
    this.repository = const FakeStudyModuleRepository(),
    this.favoritesStorage = const FavoritesStorage(),
  });

  final StudyModuleRepository repository;
  final FavoritesStorage favoritesStorage;

  /// Abre o banco local. Se não for possível (web, ou falha ao abrir o
  /// arquivo), o app segue com os dados de demonstração em vez de travar na
  /// splash.
  static Future<AppDependencies> load() async {
    final factory = platformDatabaseFactory();
    if (factory == null) return const AppDependencies();

    try {
      final db = await VetoraDatabase.open(factory: factory);
      final favorites = SqliteFavoritesStorage(db);
      await favorites.importLegacy(const FavoritesStorage());
      return AppDependencies(
        repository: SqliteStudyModuleRepository(db),
        favoritesStorage: favorites,
      );
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'vetora',
          context: ErrorDescription('ao abrir o banco SQLite'),
        ),
      );
      return const AppDependencies();
    }
  }
}
