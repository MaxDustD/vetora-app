import '../domain/engineering_area.dart';
import '../domain/module_resource.dart';
import '../domain/module_section.dart';
import '../domain/study_module.dart';
import '../domain/study_module_repository.dart';
import 'fake_module_content.dart';

/// Implementação de demonstração do [StudyModuleRepository].
///
/// O [delay] simula a rede, para que o estado de carregamento apareça; os
/// testes podem passar `Duration.zero`. Para ver os outros estados, troque
/// temporariamente o corpo de [fetchPopular] por `throw Exception()` (erro)
/// ou `return const []` (vazio).
class FakeStudyModuleRepository implements StudyModuleRepository {
  const FakeStudyModuleRepository({
    this.delay = const Duration(milliseconds: 800),
  });

  final Duration delay;

  /// Também é o catálogo gravado no SQLite na primeira abertura do app
  /// (`VetoraDatabase.seed`).
  //
  // Dados variados de propósito: um título longo, uma área com dois módulos,
  // um, dois e três recursos, durações abaixo e acima de 1 hora.
  static const List<StudyModule> modules = [
    StudyModule(
      id: 'calculo-1',
      title: 'Cálculo 1',
      subtitle: 'Funções, limites e derivadas',
      area: EngineeringArea.mathematics,
      topicCount: 3,
      durationInMinutes: 150,
      resources: {ModuleResource.theory, ModuleResource.solvedExercises},
      description:
          'A base matemática da engenharia: o que é uma função, como ela '
          'se comporta perto de um ponto e como medir a sua taxa de '
          'variação.',
    ),
    // Física do movimento e Mecânica clássica eram dois cartões para o
    // mesmo assunto (Física 1); ficaram um só módulo, com o material do
    // primeiro e o nome mais abrangente do segundo.
    StudyModule(
      id: 'mecanica-classica',
      title: 'Mecânica clássica',
      subtitle: 'Física 1',
      area: EngineeringArea.physics,
      topicCount: 4,
      durationInMinutes: 180,
      resources: {
        ModuleResource.theory,
        ModuleResource.solvedExercises,
        ModuleResource.calculator,
      },
      description:
          'Equivalente a Física 1: unidades de medida, descrição do '
          'movimento em uma dimensão, a linguagem dos vetores e as leis '
          'de Newton.',
    ),
    StudyModule(
      id: 'circuitos-eletricos',
      title: 'Circuitos elétricos',
      area: EngineeringArea.electrical,
      topicCount: 9,
      durationInMinutes: 75,
      resources: {ModuleResource.theory, ModuleResource.calculator},
    ),
    StudyModule(
      id: 'resistencia-dos-materiais',
      title: 'Resistência dos materiais',
      area: EngineeringArea.civil,
      topicCount: 10,
      durationInMinutes: 120,
      resources: {ModuleResource.theory, ModuleResource.solvedExercises},
    ),
    StudyModule(
      id: 'termodinamica',
      title: 'Termodinâmica',
      area: EngineeringArea.mechanical,
      topicCount: 8,
      durationInMinutes: 60,
      resources: {ModuleResource.theory, ModuleResource.solvedExercises},
    ),
    StudyModule(
      id: 'eletromagnetismo',
      title: 'Eletromagnetismo e ondas eletromagnéticas',
      area: EngineeringArea.physics,
      topicCount: 1,
      durationInMinutes: 45,
      resources: {ModuleResource.theory},
    ),
  ];

  @override
  Future<List<StudyModule>> fetchPopular() async {
    await Future<void>.delayed(delay);
    return modules;
  }

  @override
  Future<List<StudyModule>> fetchAll() async {
    await Future<void>.delayed(delay);
    return modules;
  }

  /// Só Cálculo 1 e Mecânica clássica têm material por enquanto; os demais
  /// devolvem lista vazia ("material em preparação").
  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) async {
    await Future<void>.delayed(delay);
    return fakeModuleContent[moduleId] ?? const [];
  }
}
