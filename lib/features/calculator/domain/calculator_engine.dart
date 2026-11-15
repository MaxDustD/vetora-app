import 'dart:math' as math;

import 'calculation_exception.dart';
import 'calculus/derivative.dart';
import 'calculus/integral.dart';
import 'calculus/limit.dart';
import 'calculus/solve.dart';
import 'compiled_function.dart';
import 'expression/expression.dart';

export 'calculation_exception.dart';
export 'calculus/limit.dart' show LimitSide;

/// Operações oferecidas pela calculadora, com os textos da interface.
enum CalculatorOperation {
  evaluate('Calcular', 'Ex.: 2^10 + √(16)/4 · sen(π/6)'),
  simplify('Simplificar', 'Ex.: (x² − 1)/(x − 1) + 2x − x'),
  expand('Expandir', 'Ex.: (x + 1)³'),
  derivative('Derivar', 'Ex.: x²·sen(x)'),
  integral('Integrar', 'Ex.: x·eˣ (sem limites = indefinida)'),
  limit('Limite', 'Ex.: sen(x)/x com x → 0'),
  solve('Resolver', 'Ex.: x² − 5x + 6 = 0'),
  taylor('Taylor', 'Ex.: eˣ em torno de 0');

  const CalculatorOperation(this.label, this.hint);

  final String label;

  /// Exemplo curto para o campo de entrada.
  final String hint;
}

/// Resultado pronto para exibir.
class CalculationResult {
  const CalculationResult({
    required this.input,
    required this.result,
    this.decimal,
    this.steps = const [],
    this.isApproximate = false,
  });

  /// O que foi calculado, como a calculadora entendeu a entrada
  /// ("d/dx [x²·sen(x)]").
  final String input;

  /// Resposta principal, exata sempre que possível ("x³/3 + C", "π/4").
  final String result;

  /// Valor decimal, quando acrescenta informação ("0,7853981634").
  final String? decimal;

  /// Passos e regras usadas, em ordem.
  final List<String> steps;

  /// A resposta veio de um método numérico (e não é exata).
  final bool isApproximate;

  @override
  String toString() =>
      '$input = $result${decimal == null ? '' : ' ≈ $decimal'}';
}

/// Motor de cálculo da calculadora: aritmética exata, simplificação,
/// derivadas, integrais, limites, equações e séries de Taylor.
///
/// Tudo é síncrono e roda em milissegundos; erros de digitação ou de
/// domínio viram [CalculationException] com mensagem para o usuário.
class CalculatorEngine {
  const CalculatorEngine();

  // ─────────────────────────── Aritmética ───────────────────────────

  CalculationResult evaluate(String source) {
    final raw = _parse(source);
    if (raw.variables.isNotEmpty) {
      final name = (raw.variables.toList()..sort()).first;
      throw CalculationException(
        'A expressão tem a variável “$name”. Para expressões com variáveis, '
        'use Simplificar, Derivar ou Integrar.',
        source.contains(name) ? source.indexOf(name) : null,
      );
    }
    _rejectInfinity(raw);
    final exact = tidy(raw);
    final value = exact.evaluate();
    if (value.isNaN) {
      throw const CalculationException(
        'O resultado não é um número real (ex.: raiz de número negativo ou '
        'logaritmo de número não positivo).',
      );
    }
    if (value.isInfinite) {
      throw const CalculationException(
        'Divisão por zero: o resultado não existe.',
      );
    }
    return CalculationResult(
      input: raw.toString(),
      result: exact.toString(),
      decimal: _decimalFor(exact),
      isApproximate: _hasApproximation(exact),
    );
  }

  CalculationResult simplify(String source) {
    final raw = _parse(source);
    _rejectInfinity(raw);
    final s = tidy(raw);
    return CalculationResult(
      input: raw.toString(),
      result: s.toString(),
      decimal: _decimalFor(s),
      isApproximate: _hasApproximation(s),
    );
  }

  CalculationResult expand(String source) {
    final raw = _parse(source);
    _rejectInfinity(raw);
    final e = _expand(raw);
    return CalculationResult(
      input: raw.toString(),
      result: e.toString(),
      decimal: _decimalFor(e),
      isApproximate: _hasApproximation(e),
      steps: const ['Distributiva e produtos notáveis, termo a termo.'],
    );
  }

  // ─────────────────────────── Derivada ───────────────────────────

  CalculationResult derivative(
    String source, {
    String variable = 'x',
    int order = 1,
    String? at,
  }) {
    if (order < 1 || order > 10) {
      throw const CalculationException('A ordem da derivada vai de 1 a 10.');
    }
    final raw = _parse(source);
    _rejectInfinity(raw);
    final f = tidy(raw);
    final rules = <DerivativeRule>{};
    final d = tidy(deriveN(f, variable, order, rules));

    final prime = order <= 3 ? "'" * order : '⁽${_sup(order)}⁾';
    final operator = order == 1
        ? 'd/d$variable'
        : 'd${_sup(order)}/d$variable${_sup(order)}';
    final steps = <String>[
      'f($variable) = $f',
      for (final r in rules) r.description,
      'f$prime($variable) = $d',
    ];

    if (at == null) {
      return CalculationResult(
        input: '$operator [$raw]',
        result: d.toString(),
        steps: steps,
      );
    }
    final point = _constant(at, 'O ponto');
    final value = tidy(substitute(d, variable, point));
    final v = value.evaluate();
    if (!v.isFinite) {
      throw CalculationException(
        'A derivada não existe em $variable = $point.',
      );
    }
    steps.add('Substituindo $variable = $point: f$prime($point) = $value');
    return CalculationResult(
      input: '$operator [$raw] em $variable = $point',
      result: value.toString(),
      decimal: _decimalFor(value),
      steps: steps,
    );
  }

  // ─────────────────────────── Integral ───────────────────────────

  CalculationResult integral(
    String source, {
    String variable = 'x',
    String? lower,
    String? upper,
  }) {
    final raw = _parse(source);
    _rejectInfinity(raw);
    final f = tidy(raw);
    if ((lower == null) != (upper == null)) {
      throw const CalculationException(
        'Informe os dois limites de integração (ou nenhum, para a '
        'integral indefinida).',
      );
    }
    final techniques = <IntegrationTechnique>{};
    final primitive = antiderivative(f, variable, techniques);
    final techniqueSteps = [for (final t in techniques) t.description];

    if (lower == null || upper == null) {
      if (primitive == null) {
        throw CalculationException(
          'Não encontrei uma primitiva de $f em termos de funções '
          'elementares. Informe limites para calcular a integral definida '
          '(numericamente).',
        );
      }
      final shown = tidy(primitive);
      return CalculationResult(
        input: '∫ $raw d$variable',
        result: '$shown + C',
        steps: [...techniqueSteps, 'Conferência: a derivada de $shown é $f.'],
      );
    }

    final a = _point(lower, 'O limite inferior');
    final b = _point(upper, 'O limite superior');
    final input =
        '∫ $raw d$variable, de $variable = ${_pointLabel(a)} '
        'a $variable = ${_pointLabel(b)}';
    final compiled = f.compile(variable);
    final aValue = _pointValue(a);
    final bValue = _pointValue(b);
    final numeric = integrateNumerically(compiled, aValue, bValue);

    if (primitive != null) {
      final steps = <String>[
        ...techniqueSteps,
        'Primitiva: F($variable) = ${tidy(primitive)}',
      ];
      // Pontos internos onde f não está definida (zeros de denominador,
      // polos de tg…): a integral imprópria é dividida neles.
      final reversed = aValue > bValue;
      final cuts = _singularPoints(
        f,
        variable,
        math.min(aValue, bValue),
        math.max(aValue, bValue),
      );
      final ordered = reversed ? cuts.reversed.toList() : cuts;
      final points = [a, for (final c in ordered) LimitPoint.finite(c), b];
      if (cuts.isEmpty) {
        steps.add(
          'Teorema Fundamental do Cálculo: ∫ = F(${_pointLabel(b)}) − '
          'F(${_pointLabel(a)})',
        );
      } else {
        steps.add(
          'f não está definida em '
          '${cuts.map((c) => '$variable = $c').join(', ')}: a integral é '
          'imprópria e é dividida nesses pontos.',
        );
      }

      Expression? total = zero;
      var divergence = 0;
      var diverges = false;
      var approximate = false;
      for (var i = 0; i + 1 < points.length; i++) {
        final fl = _primitiveAt(
          primitive,
          variable,
          points[i],
          fromAbove: !reversed,
          steps: steps,
          forceLimit: i > 0,
        );
        final fh = _primitiveAt(
          primitive,
          variable,
          points[i + 1],
          fromAbove: reversed,
          steps: steps,
          forceLimit: i + 2 < points.length,
        );
        if (fl is InfiniteLimit || fh is InfiniteLimit) {
          diverges = true;
          divergence +=
              (fh is InfiniteLimit ? fh.sign : 0) -
              (fl is InfiniteLimit ? fl.sign : 0);
        } else if (fl is FiniteLimit && fh is FiniteLimit && total != null) {
          total = add([total, sub(fh.value, fl.value)]);
          approximate = approximate || fl.approximate || fh.approximate;
        } else {
          total = null;
        }
      }

      if (diverges) {
        return CalculationResult(
          input: input,
          result: cuts.isNotEmpty || divergence == 0
              ? 'Diverge'
              : (divergence > 0 ? '+∞ (diverge)' : '$minusSign∞ (diverge)'),
          steps: [...steps, 'A integral imprópria diverge.'],
        );
      }
      if (total != null) {
        final value = tidy(total);
        final v = value.evaluate();
        // Confere com a integração numérica (protege contra primitivas
        // com saltos que a análise não detectou).
        final agrees =
            !numeric.converged ||
            (numeric.value - v).abs() <= 1e-6 * math.max(1, v.abs());
        if (v.isFinite && agrees) {
          return CalculationResult(
            input: input,
            result: value.toString(),
            decimal: _decimalFor(value),
            steps: steps,
            isApproximate: approximate || _hasApproximation(value),
          );
        }
      }
    }

    final steps = <String>[
      if (primitive == null)
        'Não há primitiva elementar conhecida: integração numérica '
            '(Gauss–Kronrod adaptativo).'
      else
        'A primitiva não pôde ser usada no intervalo: integração numérica.',
    ];
    if (!numeric.converged || !numeric.value.isFinite) {
      return CalculationResult(
        input: input,
        result: 'Diverge',
        steps: [
          ...steps,
          'A integração numérica não converge: a integral provavelmente '
              'diverge.',
        ],
        isApproximate: true,
      );
    }
    return CalculationResult(
      input: input,
      result: formatDecimal(numeric.value),
      steps: steps,
      isApproximate: true,
    );
  }

  // ─────────────────────────── Limite ───────────────────────────

  CalculationResult limit(
    String source, {
    String variable = 'x',
    required String point,
    LimitSide side = LimitSide.both,
  }) {
    final raw = _parse(source);
    _rejectInfinity(raw);
    final p = _point(point, 'O ponto do limite');
    final mark = p.isInfinite
        ? ''
        : switch (side) {
            LimitSide.both => '',
            LimitSide.left => '⁻',
            LimitSide.right => '⁺',
          };
    final input = 'lim ($variable → ${_pointLabel(p)}$mark) $raw';
    final outcome = computeLimit(raw, variable, p, side: side);
    final steps = [...outcome.steps];
    if (steps.isEmpty && outcome.value is FiniteLimit && !p.isInfinite) {
      steps.add('A função é contínua no ponto: substituição direta.');
    }
    final left = outcome.left;
    final right = outcome.right;
    if (outcome.value is NoLimit && left != null && right != null) {
      steps.add('Pela esquerda: ${_limitText(left)}.');
      steps.add('Pela direita: ${_limitText(right)}.');
    }

    return switch (outcome.value) {
      FiniteLimit(:final value, :final approximate) => CalculationResult(
        input: input,
        result: approximate
            ? formatDecimal(value.evaluate())
            : tidy(value).toString(),
        decimal: approximate ? null : _decimalFor(tidy(value)),
        steps: steps,
        isApproximate: approximate,
      ),
      InfiniteLimit(:final sign) => CalculationResult(
        input: input,
        result: sign > 0 ? '+∞' : '$minusSign∞',
        steps: steps,
      ),
      NoLimit(:final reason) => CalculationResult(
        input: input,
        result: 'Não existe',
        steps: [...steps, reason],
      ),
      _ => throw const CalculationException(
        'Não foi possível calcular o limite.',
      ),
    };
  }

  // ─────────────────────────── Equação ───────────────────────────

  CalculationResult solve(String equation, {String variable = 'x'}) {
    final Expression left;
    final Expression? right;
    try {
      (left, right) = parseEquation(equation);
    } on ExpressionException catch (e) {
      throw CalculationException(e.message, e.position);
    }
    _rejectInfinity(left);
    if (right != null) _rejectInfinity(right);
    ensureOnlyVariable(add([left, right ?? zero]), variable, equation);

    final f = tidy(sub(left, right ?? zero));
    final input = right == null ? '$left = 0' : '$left = $right';
    if (!f.dependsOn(variable)) {
      final holds = isNumber(f, 0) || f.evaluate() == 0;
      return CalculationResult(
        input: input,
        result: holds ? 'Verdadeira para todo $variable' : 'Sem solução',
        steps: ['Simplificando: $f = 0, que não depende de $variable.'],
      );
    }

    final outcome = solveEquation(f, variable);
    final steps = ['Forma f($variable) = 0: $f = 0', ...outcome.steps];
    if (outcome.truncated) {
      steps.add('Existem outras raízes fora das listadas.');
    }
    if (outcome.roots.isEmpty) {
      if (outcome.complexRoots.isNotEmpty) {
        steps.add('Raízes complexas: ${outcome.complexRoots.join('  e  ')}.');
      }
      return CalculationResult(
        input: input,
        result: outcome.complexRoots.isNotEmpty
            ? 'Sem raízes reais'
            : 'Nenhuma solução real encontrada em [${minusSign}100, 100]',
        steps: steps,
        isApproximate: outcome.complexRoots.isEmpty,
      );
    }

    final exact = outcome.roots.map((r) => '$variable = $r').join('  ou  ');
    final needsDecimal = outcome.roots.any((r) => _decimalFor(r) != null);
    return CalculationResult(
      input: input,
      result: exact,
      decimal: needsDecimal
          ? outcome.roots.map((r) => formatDecimal(r.evaluate())).join('; ')
          : null,
      steps: steps,
      isApproximate: outcome.approximate,
    );
  }

  // ─────────────────────────── Taylor ───────────────────────────

  CalculationResult taylor(
    String source, {
    String variable = 'x',
    String point = '0',
    int order = 5,
  }) {
    if (order < 1 || order > 12) {
      throw const CalculationException('A ordem da série vai de 1 a 12.');
    }
    final raw = _parse(source);
    _rejectInfinity(raw);
    ensureOnlyVariable(raw, variable, source);
    final a = _constant(point, 'O ponto');
    final x = Variable(variable);
    var d = tidy(raw);
    var factorial = Number.one;
    final terms = <Expression>[];
    final steps = <String>[];
    for (var k = 0; k <= order; k++) {
      if (k > 0) {
        d = tidy(derive(d, variable));
        factorial = factorial * Number.integer(k);
      }
      final value = tidy(substitute(d, variable, a));
      if (!value.evaluate().isFinite) {
        throw CalculationException(
          'f não é derivável $k vez(es) em $variable = $a: a série de '
          'Taylor não existe nesse ponto.',
        );
      }
      final prime = k == 0 ? '' : '⁽${_sup(k)}⁾';
      steps.add('f$prime($a) = $value');
      final term = mul([
        value,
        Constant(Number.one / factorial),
        pow(isNumber(a, 0) ? x : sub(x, a), number(k)),
      ]);
      if (!isNumber(term, 0)) terms.add(term);
    }
    final series = terms.isEmpty
        ? zero
        : (terms.length == 1 ? terms.single : Sum(terms));
    final rest = isNumber(a, 0)
        ? '$variable${_sup(order + 1)}'
        : '(${sub(x, a)})${_sup(order + 1)}';
    return CalculationResult(
      input: 'Taylor de $raw em torno de $variable = $a, ordem $order',
      result: '$series + O($rest)',
      steps: ['f(x) ≈ Σ f⁽ᵏ⁾(a)/k! · (x − a)ᵏ, k = 0…$order', ...steps],
    );
  }

  // ─────────────────────────── Apoio ───────────────────────────

  Expression _parse(String source) {
    try {
      return parseExpression(source);
    } on ExpressionException catch (e) {
      throw CalculationException(e.message, e.position);
    }
  }

  void _rejectInfinity(Expression e) {
    if (e.toString().contains('∞')) {
      throw const CalculationException(
        '“∞” só pode ser usado como ponto de limite ou extremo de integral.',
      );
    }
  }

  /// Valor constante finito (ponto de derivada, centro da série).
  Expression _constant(String source, String what) {
    final p = _point(source, what);
    if (p.isInfinite) {
      throw CalculationException('$what precisa ser um número finito.');
    }
    return p.value!;
  }

  /// Número, constante (π/2) ou ±∞.
  LimitPoint _point(String source, String what) {
    if (source.trim().isEmpty) {
      throw CalculationException('$what está vazio.');
    }
    final raw = _parse(source);
    if (raw.variables.isNotEmpty) {
      throw CalculationException('$what precisa ser um número, sem variáveis.');
    }
    final s = tidy(raw);
    if (s == NamedConstant.infinity) return const LimitPoint.infinity(1);
    if (s == neg(NamedConstant.infinity)) return const LimitPoint.infinity(-1);
    if (s.toString().contains('∞')) {
      throw CalculationException('$what não é válido.');
    }
    if (!s.evaluate().isFinite) {
      throw CalculationException('$what não é um número real.');
    }
    return LimitPoint.finite(s);
  }

  String _pointLabel(LimitPoint p) => switch (p.infinity) {
    1 => '+∞',
    -1 => '$minusSign∞',
    _ => p.value.toString(),
  };

  double _pointValue(LimitPoint p) => switch (p.infinity) {
    1 => double.infinity,
    -1 => double.negativeInfinity,
    _ => p.value!.evaluate(),
  };

  /// F no extremo: substituição direta ou, se der infinito/indefinido
  /// (extremo ∞ ou singular), limite pelo lado de dentro do intervalo.
  LimitValue _primitiveAt(
    Expression primitive,
    String variable,
    LimitPoint p, {
    required bool fromAbove,
    required List<String> steps,
    bool forceLimit = false,
  }) {
    if (!p.isInfinite && !forceLimit) {
      final direct = tidy(substitute(primitive, variable, p.value!));
      if (direct.evaluate().isFinite) return FiniteLimit(direct);
    }
    steps.add(
      'Integral imprópria: F(${_pointLabel(p)}) calculado como limite.',
    );
    return computeLimit(
      primitive,
      variable,
      p,
      side: fromAbove ? LimitSide.right : LimitSide.left,
    ).value;
  }

  /// Pontos de (lo, hi) onde f não está definida: zeros dos denominadores,
  /// polos de tg/sec/cotg/cossec e zeros do argumento de ln. Em ordem
  /// crescente.
  List<Expression> _singularPoints(
    Expression f,
    String x,
    double lo,
    double hi,
  ) {
    final sources = <String, Expression>{};
    void collect(Expression e) {
      switch (e) {
        case Power(:final base, :final exponent):
          if (exponent is Constant &&
              exponent.value.isNegative &&
              base.dependsOn(x)) {
            sources[base.key] = base;
          }
          collect(base);
          collect(exponent);
        case FunctionCall(:final function, :final argument):
          if (argument.dependsOn(x)) {
            final source = switch (function) {
              MathFunction.tan ||
              MathFunction.sec => call(MathFunction.cos, argument),
              MathFunction.cot ||
              MathFunction.csc => call(MathFunction.sin, argument),
              MathFunction.ln || MathFunction.log10 => argument,
              _ => null,
            };
            if (source != null) sources[source.key] = source;
          }
          collect(argument);
        case Sum(:final terms):
          terms.forEach(collect);
        case Product(:final factors):
          factors.forEach(collect);
        default:
          break;
      }
    }

    collect(f);
    final found = <String, Expression>{};
    for (final g in sources.values) {
      for (final r in solveEquation(g, x).roots) {
        final v = r.evaluate();
        if (v > lo && v < hi) found[r.key] = r;
      }
    }
    return found.values.toList()
      ..sort((a, b) => a.evaluate().compareTo(b.evaluate()));
  }

  Expression _expand(Expression raw) => _expandExpression(tidy(raw));

  String _limitText(LimitValue v) => switch (v) {
    FiniteLimit(:final value, :final approximate) =>
      approximate
          ? '≈ ${formatDecimal(value.evaluate())}'
          : tidy(value).toString(),
    InfiniteLimit(:final sign) => sign > 0 ? '+∞' : '$minusSign∞',
    NoLimit() => 'não existe',
    _ => '?',
  };

  /// Decimal só quando acrescenta algo (√2 → 1,414…; 3 → nada).
  String? _decimalFor(Expression e) {
    if (e.variables.isNotEmpty) return null;
    final v = e.evaluate();
    if (!v.isFinite) return null;
    final d = formatDecimal(v);
    return d == e.toString() ? null : d;
  }

  bool _hasApproximation(Expression e) => switch (e) {
    Constant(:final value) => !value.isExact,
    Sum(:final terms) => terms.any(_hasApproximation),
    Product(:final factors) => factors.any(_hasApproximation),
    Power(:final base, :final exponent) =>
      _hasApproximation(base) || _hasApproximation(exponent),
    FunctionCall(:final argument) => _hasApproximation(argument),
    _ => false,
  };

  static String _sup(int n) => superscript('$n');
}

/// Fora da classe: dentro dela, `expand` seria o método da calculadora.
Expression _expandExpression(Expression e) => expand(e);
