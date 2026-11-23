import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/favorites/data/favorites_storage.dart';
import '../features/favorites/data/sqlite_favorites_storage.dart';
import '../features/modules/data/fake_study_module_repository.dart';
import '../features/modules/data/supabase_study_module_repository.dart';
import '../features/modules/domain/study_module_repository.dart';
import 'database/platform_database_factory.dart';
import 'database/vetora_database.dart';

/// Implementações concretas escolhidas na inicialização do app.
///
/// O padrão (`const AppDependencies()`) é o de demonstração, usado pelos
/// testes de widget; [load] usa o Supabase para o catálogo.
class AppDependencies {
  const AppDependencies({
    this.repository = const FakeStudyModuleRepository(),
    this.favoritesStorage = const FavoritesStorage(),
  });

  final StudyModuleRepository repository;
  final FavoritesStorage favoritesStorage;

  /// Usa o Supabase para o catálogo e SQLite, quando disponível, para favoritos.
  static Future<AppDependencies> load({
    required SupabaseClient supabaseClient,
  }) async {
    final repository = SupabaseStudyModuleRepository(supabaseClient);
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
