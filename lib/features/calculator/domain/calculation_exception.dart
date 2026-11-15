/// Erro de cálculo ou de digitação, com mensagem pronta para o usuário.
///
/// [position] (índice a partir de 0 no texto digitado) existe quando o erro
/// é de digitação, para a interface destacar o caractere.
class CalculationException implements Exception {
  const CalculationException(this.message, [this.position]);

  final String message;
  final int? position;

  @override
  String toString() => message;
}
