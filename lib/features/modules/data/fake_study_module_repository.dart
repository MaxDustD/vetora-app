import '../domain/engineering_area.dart';
import '../domain/module_resource.dart';
import '../domain/study_module.dart';
import '../domain/study_module_repository.dart';

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

  // Dados variados de propósito: um título longo, uma área com dois módulos,
  // um, dois e três recursos, durações abaixo e acima de 1 hora.
  static const List<StudyModule> _modules = [
    StudyModule(
      id: 'mecanica-classica',
      title: 'Mecânica clássica',
      area: EngineeringArea.physics,
      topicCount: 12,
      durationInMinutes: 90,
      resources: {
        ModuleResource.theory,
        ModuleResource.solvedExercises,
        ModuleResource.calculator,
      },
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
    return _modules;
  }
}
