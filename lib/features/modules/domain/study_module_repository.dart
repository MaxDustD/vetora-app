import 'module_section.dart';
import 'study_module.dart';

/// Contrato de acesso aos módulos de estudo.
///
/// A tela depende só deste contrato; quem escolhe a implementação concreta é
/// a raiz de composição ([AppShell]). Já é assíncrono porque dados reais (API,
/// banco local) sempre levam tempo.
///
/// Os métodos retornam listas vazias quando não há resultados ou conteúdo
/// disponível. Falhas de acesso ou dados inesperados lançam
/// [StudyModuleRepositoryException].
abstract interface class StudyModuleRepository {
  /// Módulos mais estudados, do mais para o menos popular.
  Future<List<StudyModule>> fetchPopular();

  /// Catálogo completo (usado, por exemplo, para montar os favoritos).
  Future<List<StudyModule>> fetchAll();

  /// Seções do material do módulo [moduleId], na ordem de estudo.
  /// Lista vazia quando o material ainda está em preparação.
  Future<List<ModuleSection>> fetchSections(String moduleId);
}

/// Falha de acesso ao catálogo, sem expor detalhes de uma implementação.
class StudyModuleRepositoryException implements Exception {
  const StudyModuleRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'StudyModuleRepositoryException: $message ($cause)';
}
