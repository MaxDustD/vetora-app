import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({this.name = '', this.preferences = const []});

  final String name;
  final List<String> preferences;

  /// O perfil conta como completo quando o usuário informou o nome; a partir
  /// daí a Home troca o convite pelo resumo do foco de estudo.
  bool get isComplete => name.trim().isNotEmpty;

  /// Temas sugeridos. As áreas de engenharia usam os mesmos textos de
  /// `EngineeringArea.label`, o que permite à Home priorizar esses módulos.
  static const suggestions = [
    'Física',
    'Matemática',
    'Engenharia Civil',
    'Engenharia Elétrica',
    'Engenharia Mecânica',
    'Química',
  ];
}

class ProfileStorage {
  const ProfileStorage();

  static const _nameKey = 'profile_name';
  static const _preferencesKey = 'profile_preferences';

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString(_nameKey) ?? '',
      preferences: prefs.getStringList(_preferencesKey) ?? const [],
    );
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name.trim());
    await prefs.setStringList(_preferencesKey, profile.preferences);
  }
}
