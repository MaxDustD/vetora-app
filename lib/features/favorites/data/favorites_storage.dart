import 'package:shared_preferences/shared_preferences.dart';

/// Guarda os ids dos módulos favoritos, do mais recente para o mais antigo.
class FavoritesStorage {
  const FavoritesStorage();

  static const favoritesKey = 'favorite_module_ids';

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(favoritesKey) ?? const [];
  }

  Future<void> save(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(favoritesKey, ids);
  }
}
