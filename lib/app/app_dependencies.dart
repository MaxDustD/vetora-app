import 'package:flutter/foundation.dart';

import '../features/favorites/data/favorites_storage.dart';
import '../features/favorites/data/sqlite_favorites_storage.dart';
import '../features/modules/domain/study_module_repository.dart';
import 'database/platform_database_factory.dart';
import 'database/vetora_database.dart';

/// Dependências escolhidas na inicialização do app.
class AppDependencies {
  const AppDependencies({
    required this.repository,
    this.favoritesStorage = const FavoritesStorage(),
  });

  final StudyModuleRepository repository;
  final FavoritesStorage favoritesStorage;

  /// Prepara o armazenamento SQLite de favoritos, quando disponível.
  static Future<AppDependencies> load({
    required StudyModuleRepository repository,
  }) async {
    final factory = platformDatabaseFactory();
    if (factory == null) {
      return AppDependencies(
        repository: repository,
        favoritesStorage: const FavoritesStorage(),
      );
    }

    try {
      final db = await VetoraDatabase.open(factory: factory);
      final favorites = SqliteFavoritesStorage(db);
      await favorites.importLegacy(const FavoritesStorage());
      return AppDependencies(
        repository: repository,
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
      return AppDependencies(
        repository: repository,
        favoritesStorage: const FavoritesStorage(),
      );
    }
  }
}
