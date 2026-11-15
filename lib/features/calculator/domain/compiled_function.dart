import 'calculation_exception.dart';
import 'expression/expression.dart';

/// Função real de uma variável, lida uma vez e avaliada muitas (gráfico).
///
/// [call] nunca lança: fora do domínio (√ de negativo, ln 0, 1/0) devolve
/// `double.nan` ou ±infinito. Ângulos em radianos.
class CompiledFunction {
  CompiledFunction._(this.input, this.expression, this._run);

  /// A expressão como foi interpretada, em notação matemática ("2·sen(x)").
  final String input;

  /// Árvore simplificada, para quem quiser derivar ou integrar.
  final Expression expression;

  final double Function(double) _run;

  double call(double x) => _run(x);
}

/// Lê [source] como função de [variable].
///
/// Lança [CalculationException] (com posição) se a sintaxe for inválida ou
/// se aparecer outra variável além de [variable].
CompiledFunction compileFunction(String source, {String variable = 'x'}) {
  final Expression raw;
  try {
    raw = parseExpression(source);
  } on ExpressionException catch (e) {
    throw CalculationException(e.message, e.position);
  }
  ensureOnlyVariable(raw, variable, source);
  if (_containsInfinity(raw)) {
    throw const CalculationException(
      '“∞” só pode ser usado como ponto de limite ou extremo de integral.',
    );
  }
  final simplified = simplify(raw);
  return CompiledFunction._(
    raw.toString(),
    simplified,
    simplified.compile(variable),
  );
}

/// Garante que a expressão só usa [variable] (ou nenhuma variável).
void ensureOnlyVariable(Expression e, String variable, String source) {
  final others = e.variables.difference({variable});
  if (others.isEmpty) return;
  final name = (others.toList()..sort()).first;
  final index = source.indexOf(name);
  throw CalculationException(
    'Use apenas a variável $variable (encontrei “$name”).',
    index < 0 ? null : index,
  );
}

bool _containsInfinity(Expression e) => switch (e) {
  NamedConstant(:final kind) => kind == NamedConstantKind.infinity,
  Constant() || Variable() => false,
  Sum(:final terms) => terms.any(_containsInfinity),
  Product(:final factors) => factors.any(_containsInfinity),
  Power(:final base, :final exponent) =>
    _containsInfinity(base) || _containsInfinity(exponent),
  FunctionCall(:final argument) => _containsInfinity(argument),
};
