import '../../modules/domain/engineering_area.dart';
import '../../modules/domain/study_module.dart';

/// Prepara a lista "Mais estudados" para exibição.
///
/// - com [area], mostra só os módulos daquela área (filtro dos atalhos);
/// - sem filtro, coloca primeiro os módulos das áreas de interesse do perfil
///   ([interests] usa os mesmos textos de [EngineeringArea.label]), mantendo
///   a ordem de popularidade dentro de cada grupo.
///
/// Fica na apresentação, e não no repositório: é uma escolha de exibição
/// desta tela, feita sobre os dados já carregados.
List<StudyModule> arrangeModules(
  List<StudyModule> modules, {
  EngineeringArea? area,
  Iterable<String> interests = const [],
}) {
  if (area != null) {
    return [
      for (final module in modules)
        if (module.area == area) module,
    ];
  }
  final interestSet = interests.toSet();
  bool isInterest(StudyModule m) => interestSet.contains(m.area.label);
  return [
    ...modules.where(isInterest),
    ...modules.where((m) => !isInterest(m)),
  ];
}
