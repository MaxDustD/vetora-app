import 'study_module.dart';

/// Contrato de acesso aos módulos de estudo.
///
/// A tela depende só deste contrato; quem escolhe a implementação concreta é
/// a raiz de composição ([AppShell]). Já é assíncrono porque dados reais (API,
/// banco local) sempre levam tempo.
abstract interface class StudyModuleRepository {
  /// Módulos mais estudados, do mais para o menos popular.
  Future<List<StudyModule>> fetchPopular();
}
