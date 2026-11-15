/// O que um módulo oferece além do texto: cumpre a promessa "Conecte a teoria
/// à prática" do onboarding.
enum ModuleResource {
  theory('Teoria'),
  solvedExercises('Exercícios resolvidos'),
  calculator('Calculadora');

  const ModuleResource(this.label);

  final String label;
}
