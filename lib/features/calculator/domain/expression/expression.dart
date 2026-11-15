/// Expressões matemáticas: leitura, simplificação, impressão e avaliação.
///
/// Camada de domínio em Dart puro (sem Flutter): usada pelo motor de
/// cálculo e pelo gráfico.
library;

export 'ast.dart';
export 'number.dart';
export 'number_format.dart'
    show formatDecimal, formatNumber, minusSign, superscript;
export 'polynomial.dart';
export 'parser.dart' show ExpressionException, parseEquation, parseExpression;
