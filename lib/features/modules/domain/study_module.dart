import 'engineering_area.dart';
import 'module_resource.dart';

/// Um módulo de estudo (ex.: "Mecânica clássica").
///
/// Imutável e sem dependência do Flutter: a formatação ("1 h 30 min") e o
/// ícone da área ficam na camada de apresentação.
class StudyModule {
  const StudyModule({
    required this.id,
    required this.title,
    required this.area,
    required this.topicCount,
    required this.durationInMinutes,
    required this.resources,
    this.subtitle = '',
    this.description = '',
  });

  final String id;
  final String title;
  final EngineeringArea area;
  final int topicCount;
  final int durationInMinutes;
  final Set<ModuleResource> resources;

  /// Complemento do título (ex.: "Física 1"). Vazio quando não há.
  final String subtitle;

  /// Apresentação do módulo, exibida na tela do módulo.
  final String description;
}
