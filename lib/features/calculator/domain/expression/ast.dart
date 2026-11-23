import 'dart:math' as math;

import 'number.dart';
import 'number_format.dart';

/// Árvore de uma expressão matemática.
///
/// Só existem cinco formas de nó além das folhas: soma e produto n-ários,
/// potência e função. Subtração é soma com fator −1 (`a − b = a + (−1)·b`)
/// e divisão é potência −1 (`a/b = a·b⁻¹`). Com menos formas, as regras de
/// simplificação, derivação e integração ficam menores — e quem imprime
/// devolve o visual usual (`a − b`, `a/b`).
///
/// O parser constrói a árvore "crua" (como foi digitada); [simplify] e os
/// construtores [add], [mul], [pow] e [call] produzem a forma simplificada.
sealed class Expression {
  const Expression();

  /// Chave estrutural canônica: duas expressões com a mesma chave são
  /// iguais. Usada para juntar termos semelhantes (`x + x = 2x`).
  String get key;

  /// Símbolos livres (variáveis) da expressão.
  Set<String> get variables {
    final out = <String>{};
    _collectVariables(this, out);
    return out;
  }

  bool dependsOn(String variable) => _depends(this, variable);

  /// Valor real. Nunca lança: fora do domínio devolve NaN ou ±infinito;
  /// variável sem valor em [values] também resulta em NaN.
  double evaluate([Map<String, double> values = const {}]) =>
      compileWith(this, (name) => values[name] ?? double.nan)();

  /// Compila para uma função de uma variável, para avaliações repetidas
  /// (gráficos, integração numérica): a árvore é percorrida uma única vez.
  double Function(double) compile(String variable) {
    double current = double.nan;
    final run = compileWith(
      this,
      (name) => name == variable ? null : double.nan,
      variable: variable,
      read: () => current,
    );
    return (x) {
      current = x;
      return run();
    };
  }

  @override
  bool operator ==(Object other) => other is Expression && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => formatExpression(this);
}

/// Número (exato ou aproximado).
final class Constant extends Expression {
  Constant(this.value, {this.literal});
  Constant.integer(int value) : value = Number.integer(value), literal = null;

  final Number value;

  /// Como o número foi digitado ("0,1"), para mostrar a entrada sem
  /// trocá-la por 1/10. Não entra na [key]: 0,5 e 1/2 são o mesmo número.
  final String? literal;

  @override
  late final String key = 'n${value.isExact ? value : value.toDouble()}';
}

enum NamedConstantKind {
  pi('π', math.pi),
  e('e', math.e),

  /// ∞: só faz sentido como ponto de limite ou extremo de integral.
  infinity('∞', double.infinity);

  const NamedConstantKind(this.symbol, this.value);

  final String symbol;
  final double value;
}

final class NamedConstant extends Expression {
  const NamedConstant(this.kind);

  final NamedConstantKind kind;

  static const pi = NamedConstant(NamedConstantKind.pi);
  static const e = NamedConstant(NamedConstantKind.e);
  static const infinity = NamedConstant(NamedConstantKind.infinity);

  @override
  String get key => 'c${kind.name}';
}

final class Variable extends Expression {
  const Variable(this.name);

  final String name;

  @override
  String get key => 'v$name';
}

final class Sum extends Expression {
  Sum(this.terms);

  final List<Expression> terms;

  @override
  late final String key = 's(${terms.map((t) => t.key).join(',')})';
}

final class Product extends Expression {
  Product(this.factors);

  final List<Expression> factors;

  @override
  late final String key = 'p(${factors.map((t) => t.key).join(',')})';
}

final class Power extends Expression {
  Power(this.base, this.exponent);

  final Expression base;
  final Expression exponent;

  @override
  late final String key = '^(${base.key},${exponent.key})';
}

/// Funções de uma variável. [symbol] é o nome exibido (em português).
enum MathFunction {
  sin('sen'),
  cos('cos'),
  tan('tg'),
  sec('sec'),
  csc('cossec'),
  cot('cotg'),
  asin('arcsen'),
  acos('arccos'),
  atan('arctg'),
  sinh('senh'),
  cosh('cosh'),
  tanh('tgh'),
  ln('ln'),
  log10('log'),
  abs('abs');

  const MathFunction(this.symbol);

  final String symbol;

  double apply(double x) => switch (this) {
    sin => math.sin(x),
    cos => math.cos(x),
    tan => math.tan(x),
    sec => 1 / math.cos(x),
    csc => 1 / math.sin(x),
    cot => 1 / math.tan(x),
    asin => math.asin(x),
    acos => math.acos(x),
    atan => math.atan(x),
    sinh => (math.exp(x) - math.exp(-x)) / 2,
    cosh => (math.exp(x) + math.exp(-x)) / 2,
    tanh => _tanh(x),
    // ln(0) = −∞ (útil em limites); negativos ficam fora do domínio.
    ln => x < 0 ? double.nan : math.log(x),
    log10 => x < 0 ? double.nan : math.log(x) / math.ln10,
    abs => x.abs(),
  };

  static double _tanh(double x) {
    if (x > 20) return 1;
    if (x < -20) return -1;
    final a = math.exp(2 * x);
    return (a - 1) / (a + 1);
  }
}

final class FunctionCall extends Expression {
  FunctionCall(this.function, this.argument);

  final MathFunction function;
  final Expression argument;

  @override
  late final String key = 'f${function.name}(${argument.key})';
}

// ───────────────────────────── Atalhos ─────────────────────────────

final zero = Constant.integer(0);
final one = Constant.integer(1);
final minusOne = Constant.integer(-1);
final two = Constant.integer(2);
final half = Constant(Number.fraction(BigInt.one, BigInt.two));

Expression number(int value) => Constant.integer(value);

Expression neg(Expression a) => mul([minusOne, a]);
Expression sub(Expression a, Expression b) => add([a, neg(b)]);
Expression div(Expression a, Expression b) => mul([a, pow(b, minusOne)]);
Expression sqrt(Expression a) => pow(a, half);
Expression exp(Expression a) => pow(NamedConstant.e, a);

bool isNumber(Expression e, [int? value]) =>
    e is Constant &&
    (value == null || (e.value.isExact && e.value == Number.integer(value)));

/// Expressão sem variáveis (número, π, e e combinações).
bool isConstantExpression(Expression e) => e.variables.isEmpty;

// ───────────────────────────── Simplificação ─────────────────────────────

/// Reconstrói [e] pelos construtores que simplificam, de baixo para cima.
Expression simplify(Expression e) => switch (e) {
  Constant() || NamedConstant() || Variable() => e,
  Sum(:final terms) => add(terms.map(simplify).toList()),
  Product(:final factors) => mul(factors.map(simplify).toList()),
  Power(:final base, :final exponent) => pow(
    simplify(base),
    simplify(exponent),
  ),
  FunctionCall(:final function, :final argument) => call(
    function,
    simplify(argument),
  ),
};

/// Separa `3x²` em coeficiente (3) e parte literal (x²).
(Number, Expression) splitCoefficient(Expression e) {
  if (e is Constant) return (e.value, one);
  if (e is Product && e.factors.isNotEmpty && e.factors.first is Constant) {
    final rest = e.factors.sublist(1);
    final literal = rest.length == 1 ? rest.single : Product(rest);
    return ((e.factors.first as Constant).value, literal);
  }
  return (Number.one, e);
}

/// Soma simplificada: achata, soma números e junta termos semelhantes.
Expression add(List<Expression> terms) {
  var numeric = Number.zero;
  final coefficients = <String, Number>{};
  final literals = <String, Expression>{};

  void collect(Expression t) {
    if (t is Sum) {
      t.terms.forEach(collect);
    } else if (t is Constant) {
      numeric += t.value;
    } else {
      final (c, literal) = splitCoefficient(t);
      final k = literal.key;
      coefficients[k] = (coefficients[k] ?? Number.zero) + c;
      literals[k] = literal;
    }
  }

  terms.forEach(collect);

  final out = <Expression>[];
  for (final k in coefficients.keys) {
    final c = coefficients[k]!;
    if (c.isZero) continue;
    out.add(mul([Constant(c), literals[k]!]));
  }
  out.sort(_compareTerms);
  if (!numeric.isZero || out.isEmpty) out.add(Constant(numeric));
  return out.length == 1 ? out.single : Sum(out);
}

/// Produto simplificado: achata, multiplica números e junta potências de
/// mesma base (`x·x² = x³`).
Expression mul(List<Expression> factors) {
  var numeric = Number.one;
  final exponents = <String, List<Expression>>{};
  final bases = <String, Expression>{};

  void collect(Expression f) {
    if (f is Product) {
      f.factors.forEach(collect);
    } else if (f is Constant) {
      numeric *= f.value;
    } else {
      final (base, exponent) = f is Power ? (f.base, f.exponent) : (f, one);
      final k = base.key;
      (exponents[k] ??= []).add(exponent);
      bases[k] = base;
    }
  }

  factors.forEach(collect);
  if (numeric.isZero && numeric.isExact) return zero;

  final out = <Expression>[];
  for (final k in bases.keys) {
    final p = pow(bases[k]!, add(exponents[k]!));
    // A potência pode ter virado número (x⁰ = 1, 4^(1/2) = 2) ou produto
    // ((2x)² = 4x²): esses voltam para o acumulador.
    if (p is Constant) {
      numeric *= p.value;
    } else if (p is Product) {
      for (final f in p.factors) {
        if (f is Constant) {
          numeric *= f.value;
        } else {
          out.add(f);
        }
      }
    } else {
      out.add(p);
    }
  }
  if (numeric.isZero && numeric.isExact) return zero;

  out.sort(_compareFactors);
  // Número vezes soma distribui: 2(x + 1) = 2x + 2, −(x − 1) = 1 − x.
  if (!numeric.isOne && out.length == 1 && out.single is Sum) {
    return add([
      for (final t in (out.single as Sum).terms) mul([Constant(numeric), t]),
    ]);
  }
  if (!numeric.isOne) out.insert(0, Constant(numeric));
  if (out.isEmpty) return one;
  return out.length == 1 ? out.single : Product(out);
}

/// Potência simplificada.
Expression pow(Expression base, Expression exponent) {
  if (isNumber(exponent, 0)) return one;
  if (isNumber(exponent, 1)) return base;
  if (isNumber(base, 1)) return one;
  if (isNumber(base, 0) && exponent is Constant && !exponent.value.isNegative) {
    return zero;
  }

  if (base is Constant && exponent is Constant) {
    final exact = base.value.exactPow(exponent.value);
    if (exact != null) return Constant(exact);
    // Raiz irracional: tira a parte exata (√8 = 2√2) e mantém o resto.
    return _simplifyRoot(base.value, exponent.value);
  }

  // (a^b)^n = a^(b·n) para n inteiro. Para n fracionário a regra falha
  // (√(x²) = |x|, não x), então fica como está.
  if (base is Power && _isInteger(exponent)) {
    return pow(base.base, mul([base.exponent, exponent]));
  }
  // (a·b)^n = aⁿ·bⁿ para n inteiro.
  if (base is Product && _isInteger(exponent)) {
    return mul([for (final f in base.factors) pow(f, exponent)]);
  }
  // e^(ln u) = u.
  if (base is NamedConstant &&
      base.kind == NamedConstantKind.e &&
      exponent is FunctionCall &&
      exponent.function == MathFunction.ln) {
    return exponent.argument;
  }
  return Power(base, exponent);
}

bool _isInteger(Expression e) =>
    e is Constant && e.value.isExact && e.value.isInteger;

/// `8^(1/2)` → `2·2^(1/2)`. Só para expoentes 1/n com base inteira positiva.
Expression _simplifyRoot(Number base, Number exponent) {
  if (!base.isExact ||
      !exponent.isExact ||
      base is! Rational ||
      exponent is! Rational ||
      !base.isInteger ||
      base.isNegative) {
    if (!base.isExact || !exponent.isExact) {
      return Constant(
        Number.approximate(
          math.pow(base.toDouble(), exponent.toDouble()).toDouble(),
        ),
      );
    }
    return Power(Constant(base), Constant(exponent));
  }
  final p = exponent.numerator;
  final q = exponent.denominator;
  if (p != BigInt.one || q.bitLength > 6) {
    return Power(Constant(base), Constant(exponent));
  }
  final n = q.toInt();
  var rest = base.numerator;
  var outside = BigInt.one;
  // Fatores pequenos bastam para os casos de sala de aula.
  for (var f = 2; f <= 100; f++) {
    final fn = BigInt.from(f).pow(n);
    while (rest % fn == BigInt.zero && rest > BigInt.one) {
      rest ~/= fn;
      outside *= BigInt.from(f);
    }
  }
  final root = Power(
    Constant(Number.fraction(rest, BigInt.one)),
    Constant(exponent),
  );
  if (outside == BigInt.one) return root;
  return Product([Constant(Number.fraction(outside, BigInt.one)), root]);
}

/// Função simplificada: valores exatos conhecidos (sen(π/6) = 1/2,
/// ln(e) = 1, …) e números aproximados avaliados na hora.
Expression call(MathFunction function, Expression argument) {
  if (argument is Constant && !argument.value.isExact) {
    return Constant(
      Number.approximate(function.apply(argument.value.toDouble())),
    );
  }
  final exact = _exactValue(function, argument);
  if (exact != null) return exact;
  if (function == MathFunction.abs) {
    if (argument is FunctionCall && argument.function == MathFunction.abs) {
      return argument;
    }
    if (argument is Constant) return Constant(argument.value.abs());
  }
  return FunctionCall(function, argument);
}

Expression? _exactValue(MathFunction f, Expression a) {
  switch (f) {
    case MathFunction.ln:
      if (isNumber(a, 1)) return zero;
      if (a == NamedConstant.e) return one;
      if (a is Power && a.base == NamedConstant.e) return a.exponent;
    case MathFunction.log10:
      if (a is Constant && a.value is Rational) {
        final r = a.value as Rational;
        if (r.isInteger && r.numerator > BigInt.zero) {
          var n = r.numerator;
          var k = 0;
          while (n % BigInt.from(10) == BigInt.zero) {
            n ~/= BigInt.from(10);
            k++;
          }
          if (n == BigInt.one) return number(k);
        }
      }
    case MathFunction.sin || MathFunction.cos || MathFunction.tan:
      final k = _piMultiple(a);
      if (k == null) return null;
      final s = _sinOfPiMultiple(k);
      final c = _sinOfPiMultiple(k + Number.fraction(BigInt.one, BigInt.two));
      if (s == null || c == null) return null;
      return switch (f) {
        MathFunction.sin => s,
        MathFunction.cos => c,
        _ => isNumber(c, 0) ? null : simplify(div(s, c)),
      };
    case MathFunction.asin:
      return _inverseTable(a, const {
        '0': (0, 1),
        '1/2': (1, 6),
        '1': (1, 2),
        '-1/2': (-1, 6),
        '-1': (-1, 2),
      });
    case MathFunction.acos:
      return _inverseTable(a, const {
        '1': (0, 1),
        '1/2': (1, 3),
        '0': (1, 2),
        '-1/2': (2, 3),
        '-1': (1, 1),
      });
    case MathFunction.atan:
      return _inverseTable(a, const {'0': (0, 1), '1': (1, 4), '-1': (-1, 4)});
    case MathFunction.sinh || MathFunction.tanh:
      if (isNumber(a, 0)) return zero;
    case MathFunction.cosh:
      if (isNumber(a, 0)) return one;
    default:
      return null;
  }
  return null;
}

/// Ângulo dado como k·π, com k racional.
Number? _piMultiple(Expression a) {
  if (isNumber(a, 0)) return Number.zero;
  if (a == NamedConstant.pi) return Number.one;
  if (a is Product &&
      a.factors.length == 2 &&
      a.factors[0] is Constant &&
      (a.factors[0] as Constant).value.isExact &&
      a.factors[1] == NamedConstant.pi) {
    return (a.factors[0] as Constant).value;
  }
  return null;
}

/// sen(kπ) exato para múltiplos de π/6 e π/4.
Expression? _sinOfPiMultiple(Number k) {
  if (k is! Rational) return null;
  // Reduz k ao intervalo [0, 2).
  Number r = k;
  final turns = (r.toDouble() / 2).floor();
  r = r - Number.integer(turns) * Number.integer(2);
  var sign = 1;
  if (r.compareTo(Number.one) >= 0) {
    r = r - Number.one;
    sign = -1;
  }
  final halfN = Number.fraction(BigInt.one, BigInt.two);
  if (r.compareTo(halfN) > 0) r = Number.one - r;
  final Expression? base = switch ((r as Rational).toString()) {
    '0' => zero,
    '1/6' => half,
    '1/4' => mul([half, sqrt(two)]),
    '1/3' => mul([half, sqrt(number(3))]),
    '1/2' => one,
    _ => null,
  };
  if (base == null) return null;
  return sign == 1 ? base : neg(base);
}

Expression? _inverseTable(Expression a, Map<String, (int, int)> table) {
  if (a is! Constant || !a.value.isExact) return null;
  final entry = table[a.value.toString()];
  if (entry == null) return null;
  final (p, q) = entry;
  return mul([
    Constant(Number.fraction(BigInt.from(p), BigInt.from(q))),
    NamedConstant.pi,
  ]);
}

// ───────────────────────────── Ordem canônica ─────────────────────────────

/// Grau total aproximado, para listar polinômios do maior para o menor grau.
double _degree(Expression e) => switch (e) {
  Constant() || NamedConstant() => 0,
  Variable() => 1,
  Power(:final base, :final exponent) when exponent is Constant =>
    _degree(base) * exponent.value.toDouble(),
  Power() => 0.5,
  Product(:final factors) => factors.fold(0, (s, f) => s + _degree(f)),
  Sum(:final terms) => terms.map(_degree).fold(0, math.max),
  FunctionCall() => 0.5,
};

int _compareTerms(Expression a, Expression b) {
  final byDegree = _degree(b).compareTo(_degree(a));
  return byDegree != 0 ? byDegree : a.key.compareTo(b.key);
}

int _factorRank(Expression e) => switch (e) {
  Constant() => 0,
  NamedConstant() => 1,
  Variable() => 2,
  // eˣ e 2ˣ depois das variáveis: x·eˣ, não eˣ·x.
  Power(:final exponent) when exponent.variables.isNotEmpty => 3,
  Power(:final base) => _factorRank(base),
  FunctionCall() => 4,
  Sum() => 5,
  Product() => 6,
};

int _compareFactors(Expression a, Expression b) {
  final byRank = _factorRank(a).compareTo(_factorRank(b));
  if (byRank != 0) return byRank;
  final baseA = a is Power ? a.base : a;
  final baseB = b is Power ? b.base : b;
  return baseA.key.compareTo(baseB.key);
}

// ───────────────────────────── Operações ─────────────────────────────

/// Troca [variable] por [value] e simplifica.
Expression substitute(Expression e, String variable, Expression value) {
  return switch (e) {
    Variable(:final name) => name == variable ? value : e,
    Constant() || NamedConstant() => e,
    Sum(:final terms) => add([
      for (final t in terms) substitute(t, variable, value),
    ]),
    Product(:final factors) => mul([
      for (final f in factors) substitute(f, variable, value),
    ]),
    Power(:final base, :final exponent) => pow(
      substitute(base, variable, value),
      substitute(exponent, variable, value),
    ),
    FunctionCall(:final function, :final argument) => call(
      function,
      substitute(argument, variable, value),
    ),
  };
}

/// Troca toda ocorrência da subexpressão [target] por [replacement].
Expression replace(Expression e, Expression target, Expression replacement) {
  if (e == target) return replacement;
  return switch (e) {
    Variable() || Constant() || NamedConstant() => e,
    Sum(:final terms) => add([
      for (final t in terms) replace(t, target, replacement),
    ]),
    Product(:final factors) => mul([
      for (final f in factors) replace(f, target, replacement),
    ]),
    Power(:final base, :final exponent) => pow(
      replace(base, target, replacement),
      replace(exponent, target, replacement),
    ),
    FunctionCall(:final function, :final argument) => call(
      function,
      replace(argument, target, replacement),
    ),
  };
}

/// Distribui produtos sobre somas e desenvolve potências inteiras de somas
/// (até o grau 12): `(x + 1)² = x² + 2x + 1`.
Expression expand(Expression e) {
  switch (e) {
    case Sum(:final terms):
      return add(terms.map(expand).toList());
    case Product(:final factors):
      Expression acc = one;
      for (final f in factors.map(expand)) {
        acc = _multiplyOut(acc, f);
      }
      return acc;
    case Power(:final base, :final exponent):
      final b = expand(base);
      if (b is Sum &&
          exponent is Constant &&
          exponent.value.isExact &&
          exponent.value.isInteger &&
          !exponent.value.isNegative &&
          exponent.value.toDouble() <= 12) {
        // Multiplica termo a termo: chamar mul(acc, b) juntaria as bases
        // iguais de volta em (x + 1)², sem nunca terminar.
        Expression acc = one;
        for (var i = 0; i < exponent.value.toDouble().toInt(); i++) {
          acc = _multiplyOut(acc, b);
        }
        return acc;
      }
      return pow(b, expand(exponent));
    case FunctionCall(:final function, :final argument):
      return call(function, expand(argument));
    default:
      return e;
  }
}

/// Soma de frações com denominador comum (o MMC das potências):
/// `2x/(x − 1) − (x² + 1)/(x − 1)²` → `(x² − 2x − 1)/(x − 1)²`.
/// Devolve [e] quando não há o que juntar.
Expression together(Expression e) {
  if (e is! Sum) return e;
  // Fatores do denominador de cada termo, como base → expoente.
  final terms = <(Expression, Map<String, (Expression, Number)>)>[];
  final common = <String, (Expression, Number)>{};
  for (final t in e.terms) {
    final numerator = <Expression>[];
    final denominator = <String, (Expression, Number)>{};
    for (final f in t is Product ? t.factors : [t]) {
      if (f is Power &&
          f.exponent is Constant &&
          (f.exponent as Constant).value.isNegative &&
          f.base.variables.isNotEmpty) {
        final k = f.base.key;
        final exponent = -(f.exponent as Constant).value;
        denominator[k] = (f.base, exponent);
        final current = common[k];
        if (current == null || current.$2.compareTo(exponent) < 0) {
          common[k] = (f.base, exponent);
        }
      } else {
        numerator.add(f);
      }
    }
    terms.add((mul(numerator), denominator));
  }
  if (common.isEmpty) return e;

  final numerator = add([
    for (final (n, d) in terms)
      expand(
        mul([
          n,
          for (final entry in common.entries)
            pow(
              entry.value.$1,
              Constant(entry.value.$2 - (d[entry.key]?.$2 ?? Number.zero)),
            ),
        ]),
      ),
  ]);
  final denominator = mul([
    for (final (base, exponent) in common.values) pow(base, Constant(exponent)),
  ]);
  return mul([numerator, pow(denominator, minusOne)]);
}

Expression _multiplyOut(Expression a, Expression b) {
  final left = a is Sum ? a.terms : [a];
  final right = b is Sum ? b.terms : [b];
  return add([
    for (final x in left)
      for (final y in right) mul([x, y]),
  ]);
}

// ───────────────────────────── Avaliação ─────────────────────────────

void _collectVariables(Expression e, Set<String> out) {
  switch (e) {
    case Variable(:final name):
      out.add(name);
    case Sum(:final terms):
      for (final t in terms) {
        _collectVariables(t, out);
      }
    case Product(:final factors):
      for (final f in factors) {
        _collectVariables(f, out);
      }
    case Power(:final base, :final exponent):
      _collectVariables(base, out);
      _collectVariables(exponent, out);
    case FunctionCall(:final argument):
      _collectVariables(argument, out);
    case Constant() || NamedConstant():
      break;
  }
}

bool _depends(Expression e, String v) => switch (e) {
  Variable(:final name) => name == v,
  Constant() || NamedConstant() => false,
  Sum(:final terms) => terms.any((t) => _depends(t, v)),
  Product(:final factors) => factors.any((f) => _depends(f, v)),
  Power(:final base, :final exponent) =>
    _depends(base, v) || _depends(exponent, v),
  FunctionCall(:final argument) => _depends(argument, v),
};

/// Compila a árvore em closures. [lookup] dá o valor de cada variável;
/// devolver `null` indica a variável "rápida", lida por [read] a cada
/// chamada.
double Function() compileWith(
  Expression e,
  double? Function(String name) lookup, {
  String? variable,
  double Function()? read,
}) {
  double Function() c(Expression e) =>
      compileWith(e, lookup, variable: variable, read: read);

  switch (e) {
    case Constant(:final value):
      final v = value.toDouble();
      return () => v;
    case NamedConstant(:final kind):
      final v = kind.value;
      return () => v;
    case Variable(:final name):
      if (name == variable && read != null) return read;
      final v = lookup(name) ?? double.nan;
      return () => v;
    case Sum(:final terms):
      final parts = terms.map(c).toList();
      return () {
        var s = 0.0;
        for (final p in parts) {
          s += p();
        }
        return s;
      };
    case Product(:final factors):
      final parts = factors.map(c).toList();
      return () {
        var s = 1.0;
        for (final p in parts) {
          s *= p();
        }
        return s;
      };
    case Power(:final base, :final exponent):
      final b = c(base);
      // Expoente racional p/q com q ímpar: raiz real de negativos
      // (∛(−8) = −2), que math.pow devolveria como NaN.
      if (exponent is Constant && exponent.value is Rational) {
        final r = exponent.value as Rational;
        final ev = r.toDouble();
        if (!r.isInteger && r.denominator.isOdd) {
          final oddNumerator = r.numerator.isOdd;
          return () {
            final x = b();
            if (x >= 0) return math.pow(x, ev).toDouble();
            final y = math.pow(-x, ev).toDouble();
            return oddNumerator ? -y : y;
          };
        }
        if (r.isInteger) {
          return () => _powSafe(b(), ev);
        }
      }
      final ex = c(exponent);
      return () => _powSafe(b(), ex());
    case FunctionCall(:final function, :final argument):
      final a = c(argument);
      return () => function.apply(a());
  }
}

double _powSafe(double b, double e) {
  // 0⁻¹ = ±∞ (e não exceção): os limites e o gráfico dependem disso.
  return math.pow(b, e).toDouble();
}

/// Formata a expressão para leitura, em notação matemática com Unicode.
String formatExpression(Expression e) => ExpressionPrinter.format(e);
