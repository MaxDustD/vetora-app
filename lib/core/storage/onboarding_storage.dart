import 'package:shared_preferences/shared_preferences.dart';

/// Guarda se o onboarding já foi concluído (Trabalho 1, seção 09).
///
/// Única informação persistida pelo app. Splash e Onboarding não acessam o
/// armazenamento diretamente: a Splash só lê ([isCompleted]) e o Onboarding
/// só escreve ([markCompleted]).
class OnboardingStorage {
  const OnboardingStorage();

  static const onboardingCompletedKey = 'onboarding_completed';

  /// Retorna `true` se o onboarding já foi concluído.
  ///
  /// Chave ausente (primeira execução) é tratada como `false`.
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingCompletedKey) ?? false;
  }

  /// Grava a conclusão. Deve ser aguardado antes de navegar para a Home.
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, true);
  }

  /// Volta a chave para `false`. Usado apenas pelo botão de depuração da Home.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, false);
  }
}
