import '../domain/engineering_area.dart';
import '../domain/module_resource.dart';

/// Textos que representam as enums do domínio no banco de dados.
///
/// Ficam fixos aqui, e não em `enum.name`, para que renomear uma constante
/// no código não invalide os dados já gravados. São minúsculos e em
/// snake_case, como pedem os `CHECK` do SQLite e do Supabase.
abstract final class ModuleStorageKeys {
  static const areas = {
    EngineeringArea.physics: 'physics',
    EngineeringArea.mathematics: 'mathematics',
    EngineeringArea.civil: 'civil',
    EngineeringArea.electrical: 'electrical',
    EngineeringArea.mechanical: 'mechanical',
  };

  static const resources = {
    ModuleResource.theory: 'theory',
    ModuleResource.solvedExercises: 'solved_exercises',
    ModuleResource.calculator: 'calculator',
  };

  static EngineeringArea areaFrom(String key) => _parse(areas, key, 'área');

  static ModuleResource resourceFrom(String key) =>
      _parse(resources, key, 'recurso');

  static T _parse<T>(Map<T, String> keys, String key, String what) {
    for (final entry in keys.entries) {
      if (entry.value == key) return entry.key;
    }
    throw FormatException('Valor de $what desconhecido: $key');
  }

  /// Lista para um `CHECK (coluna IN (...))`.
  static String sqlList(Iterable<String> values) =>
      values.map((v) => "'$v'").join(', ');
}
