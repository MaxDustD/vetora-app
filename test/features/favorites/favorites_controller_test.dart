import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetora/features/favorites/data/favorites_storage.dart';
import 'package:vetora/features/favorites/presentation/favorites_controller.dart';

class _FailingStorage extends FavoritesStorage {
  const _FailingStorage();

  @override
  Future<List<String>> load() async => ['a'];

  @override
  Future<void> save(List<String> ids) => Future.error(Exception('disco cheio'));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('carrega os favoritos salvos', () async {
    SharedPreferences.setMockInitialValues({
      FavoritesStorage.favoritesKey: ['b', 'a'],
    });
    final favorites = FavoritesController();
    expect(favorites.isLoaded, isFalse);

    await favorites.load();

    expect(favorites.isLoaded, isTrue);
    expect(favorites.ids, ['b', 'a']);
    expect(favorites.isFavorite('a'), isTrue);
    expect(favorites.isFavorite('c'), isFalse);
  });

  test('favoritar coloca o módulo no início e grava', () async {
    final favorites = FavoritesController();
    await favorites.load();

    expect(await favorites.toggle('a'), isTrue);
    expect(await favorites.toggle('b'), isTrue);

    expect(favorites.ids, ['b', 'a']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(FavoritesStorage.favoritesKey), ['b', 'a']);
  });

  test('tocar de novo remove o favorito', () async {
    final favorites = FavoritesController();
    await favorites.load();
    await favorites.toggle('a');

    expect(await favorites.toggle('a'), isFalse);
    expect(favorites.ids, isEmpty);
  });

  test('avisa os ouvintes a cada mudança', () async {
    final favorites = FavoritesController();
    var notifications = 0;
    favorites.addListener(() => notifications++);

    await favorites.load();
    await favorites.toggle('a');

    expect(notifications, 2);
  });

  test('se a gravação falha, desfaz a mudança e relança o erro', () async {
    final favorites = FavoritesController(storage: const _FailingStorage());
    await favorites.load();

    await expectLater(favorites.toggle('b'), throwsException);
    expect(favorites.ids, ['a']);
  });
}
