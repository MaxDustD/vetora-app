import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';
import 'package:vetora/features/modules/domain/module_search.dart';
import 'package:vetora/features/modules/domain/study_module.dart';

const _calculo = StudyModule(
  id: 'calculo',
  title: 'Cálculo 1',
  subtitle: 'Funções e derivadas',
  area: EngineeringArea.mathematics,
  topicCount: 3,
  durationInMinutes: 150,
  resources: {ModuleResource.theory},
);

const _bistro = StudyModule(
  id: 'mecanica',
  title: 'Mecânica clássica',
  subtitle: 'Física 1',
  area: EngineeringArea.physics,
  topicCount: 4,
  durationInMinutes: 180,
  resources: {ModuleResource.theory},
);

void main() {
  test('normaliza acentos e encontra todas as palavras', () {
    expect(normalizeSearchText('  CAFÉ  '), 'cafe');

    final result = applyModuleSearch(const [
      _calculo,
      _bistro,
    ], const ModuleSearchFilters(query: 'calculo derivadas'));

    expect(result.map((module) => module.id), ['calculo']);
  });

  test('combina áreas por OU e opções por E', () {
    const filters = ModuleSearchFilters(
      areas: {EngineeringArea.mathematics, EngineeringArea.physics},
    );
    expect(applyModuleSearch(const [_calculo, _bistro], filters), [
      _calculo,
      _bistro,
    ]);

    final favorites = applyModuleSearch(
      const [_calculo, _bistro],
      const ModuleSearchFilters(
        areas: {EngineeringArea.mathematics},
        onlyFavorites: true,
      ),
      favoriteIds: const {'calculo'},
    );
    expect(favorites.map((module) => module.id), ['calculo']);
  });

  test('activeCount ignora ordenação e cleared preserva a ordenação', () {
    const filters = ModuleSearchFilters(
      query: 'cálculo',
      areas: {EngineeringArea.mathematics},
      onlyFavorites: true,
      sort: ModuleSearchSort.duration,
    );
    expect(filters.activeCount, 3);
    expect(filters.cleared().query, '');
    expect(filters.cleared().sort, ModuleSearchSort.duration);
  });

  test('Sets com mesmo conteúdo têm igualdade por conteúdo', () {
    const first = ModuleSearchFilters(
      areas: {EngineeringArea.physics, EngineeringArea.mathematics},
    );
    const second = ModuleSearchFilters(
      areas: {EngineeringArea.mathematics, EngineeringArea.physics},
    );
    expect(first, second);
  });
}
