import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/modules/data/study_module_json.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';

void main() {
  test('converte um registro Supabase mantendo o slug como id do app', () {
    final module = StudyModuleJson.fromMap(
      {
        'slug': 'calculo-1',
        'title': 'Cálculo 1',
        'subtitle': 'Funções, limites e derivadas',
        'area': 'mathematics',
        'topic_count': 3,
        'duration_in_minutes': 150,
        'resources': ['theory', 'solved_exercises'],
      },
      description: 'Descrição do módulo',
      coverImageUrl: 'https://example.test/calculo-1/capa.png',
    );

    expect(module.id, 'calculo-1');
    expect(module.area, EngineeringArea.mathematics);
    expect(module.resources, {
      ModuleResource.theory,
      ModuleResource.solvedExercises,
    });
    expect(module.description, 'Descrição do módulo');
    expect(module.coverImageUrl, 'https://example.test/calculo-1/capa.png');
  });

  test('rejeita chaves de domínio desconhecidas', () {
    expect(
      () => StudyModuleJson.fromMap({
        'slug': 'calculo-1',
        'title': 'Cálculo 1',
        'subtitle': '',
        'area': 'mathematics',
        'topic_count': 3,
        'duration_in_minutes': 150,
        'resources': ['unknown'],
      }, description: ''),
      throwsFormatException,
    );
  });
}
