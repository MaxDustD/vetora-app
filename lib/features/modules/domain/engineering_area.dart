/// Áreas de estudo do Vetora: um conjunto fechado, que só muda com uma nova
/// versão do app.
///
/// A ordem da declaração é a ordem dos atalhos na Home. [label] é o nome
/// completo (o mesmo usado nas preferências do perfil) e [shortLabel], a
/// versão que cabe no atalho.
enum EngineeringArea {
  physics('Física', 'Física'),
  mathematics('Matemática', 'Matemática'),
  civil('Engenharia Civil', 'Civil'),
  electrical('Engenharia Elétrica', 'Elétrica'),
  mechanical('Engenharia Mecânica', 'Mecânica');

  const EngineeringArea(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}
