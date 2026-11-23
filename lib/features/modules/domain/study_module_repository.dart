import 'module_section.dart';
import 'study_module.dart';

/// Contrato de acesso aos módulos de estudo.
///
/// A tela depende só deste contrato; quem escolhe a implementação concreta é
/// a raiz de composição ([AppShell]). Já é assíncrono porque dados reais (API,
/// banco local) sempre levam tempo.
abstract interface class StudyModuleRepository {
  /// Módulos mais estudados, do mais para o menos popular.
  Future<List<StudyModule>> fetchPopular();

  /// Catálogo completo (usado, por exemplo, para montar os favoritos).
  Future<List<StudyModule>> fetchAll();

  /// Seções do material do módulo [moduleId], na ordem de estudo.
  /// Lista vazia quando o material ainda está em preparação.
  Future<List<ModuleSection>> fetchSections(String moduleId);
}
