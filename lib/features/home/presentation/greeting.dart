/// Saudação conforme a hora. Função pura: recebe o horário em vez de chamar
/// `DateTime.now()`, para que as fronteiras (11h59, 12h, 4h59) sejam testáveis.
String greetingFor(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Bom dia';
  if (hour >= 12 && hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
