import 'package:sqflite/sqflite.dart';

import 'favorites_storage.dart';

/// Favoritos guardados na tabela `favorites` do banco SQLite local.
///
/// Implementa a mesma interface de [FavoritesStorage], então o
/// `FavoritesController` e as telas não percebem a troca.
class SqliteFavoritesStorage implements FavoritesStorage {
  const SqliteFavoritesStorage(this.db);

  final Database db;

  @override
  Future<List<String>> load() async {
    final rows = await db.query(
      'favorites',
      columns: ['module_id'],
      orderBy: 'position',
    );
    return [for (final row in rows) row['module_id']! as String];
  }

  /// Substitui a lista inteira numa transação: ou grava tudo, ou nada (e o
  /// controller desfaz a mudança otimista).
  @override
  Future<void> save(List<String> ids) {
    return db.transaction((txn) async {
      await txn.delete('favorites');
      final batch = txn.batch();
      for (final (position, id) in ids.indexed) {
        batch.insert('favorites', {'module_id': id, 'position': position});
      }
      await batch.commit(noResult: true);
    });
  }

  /// Traz, uma única vez, os favoritos gravados no `shared_preferences` pelas
  /// versões anteriores do app, e depois limpa a lista antiga.
  ///
  /// Ids de módulos que não existem mais no catálogo (ex.: "Física do
  /// movimento", unido à Mecânica clássica) são descartados.
  Future<void> importLegacy(FavoritesStorage legacy) async {
    final legacyIds = await legacy.load();
    if (legacyIds.isEmpty) return;

    final known = {
      for (final row in await db.query('study_modules', columns: ['id']))
        row['id']! as String,
    };
    final current = await load();
    await save([
      ...current,
      for (final id in legacyIds)
        if (known.contains(id) && !current.contains(id)) id,
    ]);
    await legacy.save(const []);
  }
}
