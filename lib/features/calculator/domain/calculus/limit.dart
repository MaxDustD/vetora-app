import 'dart:math' as math;

import '../expression/expression.dart';
import 'derivative.dart';

/// Lado de aproximação do limite.
enum LimitSide {
  both('Bilateral'),
  left('Pela esquerda'),
  right('Pela direita');

  const LimitSide(this.label);

  final String label;
}

/// Resultado de um limite.
sealed class LimitValue {
  const LimitValue();
}

final class FiniteLimit extends LimitValue {
  const FiniteLimit(this.value, {this.approximate = false});

  /// Expressão constante (exata, como π/2, ou um decimal aproximado).
  final Expression value;
  final bool approximate;

  double get numeric => value.evaluate();
}

final class InfiniteLimit extends LimitValue {
  const InfiniteLimit(this.sign);

  /// +1 para +∞, −1 para −∞.
  final int sign;
}

/// O limite não existe (oscila, laterais diferentes, fora do domínio…).
final class NoLimit extends LimitValue {
  const NoLimit(this.reason);

  final String reason;
}

/// Indeterminação que a parte simbólica não resolveu: vai para a
/// estimativa numérica. Nunca sai deste arquivo.
final class _Unknown extends LimitValue {
  const _Unknown();
}

/// Ponto do limite: um valor finito (constante) ou ±∞.
class LimitPoint {
  const LimitPoint.finite(Expression this.value) : infinity = 0;
  const LimitPoint.infinity(this.infinity) : value = null;

  final Expression? value;

  /// 0 para ponto finito; +1 para +∞; −1 para −∞.
  final int infinity;

  bool get isInfinite => infinity != 0;
}

class LimitOutcome {
  const LimitOutcome(this.value, this.steps, {this.left, this.right});

  final LimitValue value;
  final List<String> steps;

  /// Laterais calculados (só no limite bilateral em ponto finito).
  final LimitValue? left;
  final LimitValue? right;

  bool get approximate =>
      value is FiniteLimit && (value as FiniteLimit).approximate;
}

/// Calcula lim (x→ponto) f(x).
///
/// Estratégia, em ordem:
/// 1. aritmética de limites nos reais estendidos (inclui ±∞): resolve
///    substituição direta, `c/0`, `1/∞`, `e^(−∞)`, `arctg(∞)`…;
/// 2. indeterminações 0/0 e ∞/∞ (e 0·∞, ∞ − ∞ e 1^∞, reescritas como
///    quociente) pela regra de L'Hôpital, até 8 vezes;
/// 3. se nada disso resolver, estimativa numérica — e o resultado é marcado
///    como aproximado.
LimitOutcome computeLimit(
  Expression f,
  String variable,
  LimitPoint point, {
  LimitSide side = LimitSide.both,
}) {
  final expression = simplify(f);
  final steps = <String>[];

  LimitValue oneSide(int direction) {
    final engine = _LimitEngine(variable, point, direction, steps);
    var v = engine.limit(expression);
    if (v is _Unknown) {
      steps.add(
        point.isInfinite
            ? 'Estimativa numérica: avaliando f para x cada vez maior em '
                  'módulo.'
            : 'Estimativa numérica: avaliando f(x) com x cada vez mais '
                  'próximo do ponto.',
      );
      v = _numeric(expression, variable, point, direction);
    }
    return v;
  }

  if (point.isInfinite) {
    final v = oneSide(-point.infinity);
    return LimitOutcome(v, _dedupe(steps));
  }
  if (side == LimitSide.left) return LimitOutcome(oneSide(-1), _dedupe(steps));
  if (side == LimitSide.right) return LimitOutcome(oneSide(1), _dedupe(steps));

  final left = oneSide(-1);
  final right = oneSide(1);
  return LimitOutcome(
    _combine(left, right),
    _dedupe(steps),
    left: left,
    right: right,
  );
}

List<String> _dedupe(List<String> steps) {
  final seen = <String>{};
  return [
    for (final s in steps)
      if (seen.add(s)) s,
  ];
}

LimitValue _combine(LimitValue left, LimitValue right) {
  if (left is NoLimit) return left;
  if (right is NoLimit) return right;
  if (left is InfiniteLimit && right is InfiniteLimit) {
    if (left.sign == right.sign) return left;
  }
  if (left is FiniteLimit && right is FiniteLimit) {
    if (left.value == right.value) return left.approximate ? right : left;
    final l = left.numeric;
    final r = right.numeric;
    final tolerance = (left.approximate || right.approximate) ? 1e-5 : 1e-12;
    if ((l - r).abs() <= tolerance * math.max(1, l.abs())) {
      return left.approximate ? right : left;
    }
  }
  return const NoLimit(
    'Os limites laterais são diferentes, então o limite bilateral não '
    'existe.',
  );
}

class _LimitEngine {
  _LimitEngine(this.x, this.point, this.direction, this.steps);

  final String x;
  final LimitPoint point;

  /// +1: pela direita (ou x → −∞, vindo de valores maiores);
  /// −1: pela esquerda (ou x → +∞).
  final int direction;
  final List<String> steps;

  var _hopitalCount = 0;
  static const _maxHopital = 8;

  late final double _a = point.value?.evaluate() ?? 0;

  bool _isZero(LimitValue v) =>
      v is FiniteLimit && (isNumber(v.value, 0) || v.numeric == 0);

  int _signOf(LimitValue v) => switch (v) {
    FiniteLimit() => v.numeric.sign.toInt(),
    InfiniteLimit(:final sign) => sign,
    _ => 0,
  };

  /// Sinal de [e] bem perto do ponto, do lado em estudo. 0 se indefinido.
  int _signNear(Expression e) {
    final f = e.compile(x);
    for (final t in const [1e-6, 1e-4, 1e-8]) {
      final at = point.isInfinite
          ? point.infinity / t
          : _a + direction * t * math.max(1, _a.abs());
      final y = f(at);
      if (y.isFinite && y != 0) return y.sign.toInt();
      if (y.isInfinite) return y > 0 ? 1 : -1;
    }
    return 0;
  }

  LimitValue limit(Expression e) {
    if (!e.dependsOn(x)) {
      final v = e.evaluate();
      if (v.isFinite) return FiniteLimit(e);
      return const _Unknown();
    }
    return switch (e) {
      Variable() =>
        point.isInfinite
            ? InfiniteLimit(point.infinity)
            : FiniteLimit(point.value!),
      Sum(:final terms) => _sum(e, terms),
      Product() => _product(e),
      Power(:final base, :final exponent) => _power(base, exponent),
      FunctionCall(:final function, :final argument) => _function(
        function,
        argument,
      ),
      Constant() || NamedConstant() => FiniteLimit(e),
    };
  }

  // ─────────────── Soma ───────────────

  LimitValue _sum(Expression whole, List<Expression> terms) {
    final values = terms.map(limit).toList();
    if (values.any((v) => v is NoLimit)) {
      // Limitada + infinito ainda é infinito; o resto fica para o numérico.
      return values.any((v) => v is InfiniteLimit)
          ? const _Unknown()
          : values.firstWhere((v) => v is NoLimit);
    }
    if (values.any((v) => v is _Unknown)) return const _Unknown();

    final infinite = values
        .whereType<InfiniteLimit>()
        .map((v) => v.sign)
        .toSet();
    if (infinite.length == 2) {
      final conjugate = _conjugate(terms);
      if (conjugate != null) {
        steps.add('Indeterminação ∞ − ∞: multiplicando pelo conjugado.');
        return _quotient(conjugate.$1, conjugate.$2);
      }
      steps.add('Indeterminação ∞ − ∞: reescrevendo como uma única fração.');
      final (n, d) = _asFraction(whole);
      if (isNumber(d, 1)) return const _Unknown();
      return _quotient(n, d);
    }
    if (infinite.length == 1) return InfiniteLimit(infinite.single);
    return FiniteLimit(
      add([for (final v in values) (v as FiniteLimit).value]),
      approximate: values.any((v) => (v as FiniteLimit).approximate),
    );
  }

  /// a + b com uma raiz quadrada: a + b = (a² − b²)/(a − b).
  (Expression, Expression)? _conjugate(List<Expression> terms) {
    if (terms.length != 2) return null;
    bool hasRoot(Expression e) {
      final (_, literal) = splitCoefficient(e);
      return literal is Power &&
          literal.exponent is Constant &&
          (literal.exponent as Constant).value == half.value;
    }

    if (!terms.any(hasRoot)) return null;
    final [a, b] = terms;
    return (expand(sub(pow(a, two), pow(b, two))), sub(a, b));
  }

  /// Junta uma soma de frações: a/b + c/d = (ad + cb)/(bd).
  (Expression, Expression) _asFraction(Expression e) {
    if (e is! Sum) return _split(e);
    final parts = e.terms.map(_split).toList();
    final denominator = mul([for (final (_, d) in parts) d]);
    final numerator = add([
      for (var i = 0; i < parts.length; i++)
        mul([
          parts[i].$1,
          for (var j = 0; j < parts.length; j++)
            if (j != i) parts[j].$2,
        ]),
    ]);
    return (expand(numerator), denominator);
  }

  /// Separa numerador e denominador (fatores com expoente negativo).
  (Expression, Expression) _split(Expression e) {
    final factors = e is Product ? e.factors : [e];
    final numerator = <Expression>[];
    final denominator = <Expression>[];
    for (final f in factors) {
      if (f is Power &&
          f.exponent is Constant &&
          (f.exponent as Constant).value.isNegative) {
        denominator.add(pow(f.base, neg(f.exponent)));
      } else if (f is Constant && f.value is Rational && !f.value.isInteger) {
        final r = f.value as Rational;
        numerator.add(Constant(Number.fraction(r.numerator, BigInt.one)));
        denominator.add(Constant(Number.fraction(r.denominator, BigInt.one)));
      } else {
        numerator.add(f);
      }
    }
    return (mul(numerator), mul(denominator));
  }

  // ─────────────── Produto e quociente ───────────────

  LimitValue _product(Expression e) {
    final (n, d) = _split(e);
    if (!d.dependsOn(x)) {
      final factors = n is Product ? n.factors : [n];
      return _scale(_productOf(factors), d);
    }
    return _quotient(n, d);
  }

  LimitValue _scale(LimitValue v, Expression constantDenominator) {
    if (isNumber(constantDenominator, 1)) return v;
    return switch (v) {
      FiniteLimit(:final value, :final approximate) => FiniteLimit(
        div(value, constantDenominator),
        approximate: approximate,
      ),
      InfiniteLimit(:final sign) => InfiniteLimit(
        sign * constantDenominator.evaluate().sign.toInt(),
      ),
      _ => v,
    };
  }

  LimitValue _productOf(List<Expression> factors) {
    final values = factors.map(limit).toList();
    if (values.any((v) => v is _Unknown)) return const _Unknown();
    if (values.any((v) => v is NoLimit)) {
      final oscillating = [
        for (var i = 0; i < factors.length; i++)
          if (values[i] is NoLimit) factors[i],
      ];
      if (values.any(_isZero) &&
          oscillating.every(_isBounded) &&
          !values.any((v) => v is InfiniteLimit)) {
        return _squeeze();
      }
      return values.any(_isZero)
          ? const _Unknown()
          : values.firstWhere((v) => v is NoLimit);
    }

    final zeros = <Expression>[];
    final infinities = <Expression>[];
    for (var i = 0; i < factors.length; i++) {
      if (_isZero(values[i])) zeros.add(factors[i]);
      if (values[i] is InfiniteLimit) infinities.add(factors[i]);
    }
    if (zeros.isNotEmpty && infinities.isNotEmpty) {
      // 0·∞: u·v = v/(1/u) ou u/(1/v). Inverte o lado cujo inverso é
      // simples (potências e exponenciais: x → x⁻¹, e⁻ˣ → eˣ); inverter um
      // logaritmo deixaria as derivadas cada vez maiores.
      steps.add('Indeterminação 0·∞: reescrevendo como quociente.');
      final invertZeros =
          zeros.every(_isPowerLike) || !infinities.every(_isPowerLike);
      final inverted = invertZeros ? zeros : infinities;
      final others = [
        for (final f in factors)
          if (!inverted.contains(f)) f,
      ];
      return _quotient(mul(others), pow(mul(inverted), minusOne));
    }

    if (infinities.isNotEmpty) {
      var sign = 1;
      for (final v in values) {
        sign *= _signOf(v);
      }
      return InfiniteLimit(sign);
    }
    return FiniteLimit(
      mul([for (final v in values) (v as FiniteLimit).value]),
      approximate: values.any((v) => (v as FiniteLimit).approximate),
    );
  }

  bool _isPowerLike(Expression e) => e is Variable || e is Power;

  /// Funções limitadas (|f| ≤ M): sen, cos, arctg, tgh e combinações.
  bool _isBounded(Expression e) => switch (e) {
    Constant() || NamedConstant() => true,
    FunctionCall(:final function) => const {
      MathFunction.sin,
      MathFunction.cos,
      MathFunction.atan,
      MathFunction.tanh,
    }.contains(function),
    Sum(:final terms) => terms.every(_isBounded),
    Product(:final factors) => factors.every(_isBounded),
    Power(:final base, :final exponent) =>
      _isBounded(base) &&
          exponent is Constant &&
          exponent.value.isInteger &&
          !exponent.value.isNegative,
    _ => false,
  };

  LimitValue _squeeze() {
    steps.add(
      'Teorema do confronto: um fator limitado multiplicado por algo que '
      'tende a 0 tende a 0.',
    );
    return FiniteLimit(zero);
  }

  LimitValue _quotient(Expression n, Expression d) {
    final ln = limit(n);
    final ld = limit(d);
    if (ln is _Unknown || ld is _Unknown) return const _Unknown();
    if (ln is NoLimit && ld is InfiniteLimit && _isBounded(n)) {
      return _squeeze();
    }
    if (ln is NoLimit) return ld is InfiniteLimit ? const _Unknown() : ln;
    if (ld is NoLimit) return ld;

    if (ld is FiniteLimit && !_isZero(ld)) {
      if (ln is FiniteLimit) {
        return FiniteLimit(
          div(ln.value, ld.value),
          approximate: ln.approximate || ld.approximate,
        );
      }
      return InfiniteLimit(_signOf(ln) * _signOf(ld));
    }

    if (ld is FiniteLimit) {
      // Denominador → 0.
      if (_isZero(ln)) return _hopital(n, d, '0/0');
      final s = _signNear(d);
      if (s == 0) {
        return const NoLimit('A função não está definida perto do ponto.');
      }
      return InfiniteLimit(_signOf(ln) * s);
    }

    // Denominador → ±∞.
    if (ln is FiniteLimit) return FiniteLimit(zero);
    return _hopital(n, d, '∞/∞');
  }

  LimitValue _hopital(Expression n, Expression d, String form) {
    if (_hopitalCount >= _maxHopital) return const _Unknown();
    _hopitalCount++;
    final dn = derive(n, x);
    final dd = derive(d, x);
    if (isNumber(dd, 0)) return const _Unknown();
    final q = simplify(div(dn, dd));
    steps.add(
      "Indeterminação $form: pela regra de L'Hôpital, lim f/g = lim f'/g' "
      '= lim $q',
    );
    return limit(q);
  }

  // ─────────────── Potência ───────────────

  LimitValue _power(Expression base, Expression exponent) {
    if (!exponent.dependsOn(x)) {
      final ev = exponent.evaluate();
      if (ev < 0) return _quotient(one, pow(base, neg(exponent)));
      final lb = limit(base);
      final integer = ev == ev.roundToDouble();
      final oddRoot =
          exponent is Constant &&
          exponent.value is Rational &&
          (exponent.value as Rational).denominator.isOdd;
      switch (lb) {
        case FiniteLimit(:final value, :final approximate):
          final b = lb.numeric;
          if (b < 0 && !integer && !oddRoot) {
            return const NoLimit('Raiz de número negativo: fora do domínio.');
          }
          if (b == 0 && !integer && !oddRoot && _signNear(base) < 0) {
            return const NoLimit(
              'A função não está definida desse lado do ponto (raiz de '
              'número negativo).',
            );
          }
          return FiniteLimit(pow(value, exponent), approximate: approximate);
        case InfiniteLimit(:final sign):
          if (sign > 0) return const InfiniteLimit(1);
          if (integer) return InfiniteLimit(ev.toInt().isEven ? 1 : -1);
          if (oddRoot) {
            final p = (exponent.value as Rational).numerator;
            return InfiniteLimit(p.isEven ? 1 : -1);
          }
          return const NoLimit('Raiz de número negativo: fora do domínio.');
        default:
          return lb;
      }
    }

    if (!base.dependsOn(x)) {
      final c = base.evaluate();
      final le = limit(exponent);
      switch (le) {
        case FiniteLimit(:final value, :final approximate):
          return FiniteLimit(pow(base, value), approximate: approximate);
        case InfiniteLimit(:final sign):
          if (c == 1) return FiniteLimit(one);
          if (c <= 0) return const NoLimit('Base não positiva.');
          final grows = (c > 1) == (sign > 0);
          return grows ? const InfiniteLimit(1) : FiniteLimit(zero);
        default:
          return le;
      }
    }

    // uᵛ = e^(v·ln u): cobre 1^∞, 0⁰ e ∞⁰.
    steps.add('Potência variável: uᵛ = e^(v·ln u).');
    final inner = limit(mul([exponent, call(MathFunction.ln, base)]));
    return switch (inner) {
      FiniteLimit(:final value, :final approximate) => FiniteLimit(
        exp(value),
        approximate: approximate,
      ),
      InfiniteLimit(:final sign) =>
        sign > 0 ? const InfiniteLimit(1) : FiniteLimit(zero),
      _ => inner,
    };
  }

  // ─────────────── Funções ───────────────

  LimitValue _function(MathFunction f, Expression u) {
    // tg, sec, cossec e cotg têm polos: viram quocientes de sen e cos,
    // que o quociente já sabe tratar.
    Expression s() => call(MathFunction.sin, u);
    Expression c() => call(MathFunction.cos, u);
    switch (f) {
      case MathFunction.tan:
        return _quotient(s(), c());
      case MathFunction.cot:
        return _quotient(c(), s());
      case MathFunction.sec:
        return _quotient(one, c());
      case MathFunction.csc:
        return _quotient(one, s());
      default:
        break;
    }

    final lu = limit(u);
    switch (lu) {
      case FiniteLimit(:final value, :final approximate):
        final v = lu.numeric;
        switch (f) {
          case MathFunction.ln || MathFunction.log10:
            if (v > 0) break;
            if (v == 0 && _signNear(u) > 0) return const InfiniteLimit(-1);
            return const NoLimit('Logaritmo de número não positivo.');
          case MathFunction.asin || MathFunction.acos:
            if (v.abs() > 1) {
              return const NoLimit('Fora do domínio de arcsen/arccos.');
            }
          default:
            break;
        }
        return FiniteLimit(call(f, value), approximate: approximate);
      case InfiniteLimit(:final sign):
        return switch (f) {
          MathFunction.sin || MathFunction.cos => const NoLimit(
            'A função oscila e não se aproxima de nenhum valor.',
          ),
          MathFunction.atan => FiniteLimit(
            mul([
              Constant(Number.fraction(BigInt.from(sign), BigInt.two)),
              NamedConstant.pi,
            ]),
          ),
          MathFunction.ln || MathFunction.log10 =>
            sign > 0
                ? const InfiniteLimit(1)
                : const NoLimit('Logaritmo de número negativo.'),
          MathFunction.sinh => InfiniteLimit(sign),
          MathFunction.cosh || MathFunction.abs => const InfiniteLimit(1),
          MathFunction.tanh => FiniteLimit(number(sign)),
          _ => const NoLimit('Fora do domínio da função.'),
        };
      default:
        return lu;
    }
  }
}

/// Estimativa numérica: avalia f em pontos cada vez mais próximos e observa
/// para onde os valores vão. Usada só quando a parte simbólica não decide.
LimitValue _numeric(Expression e, String x, LimitPoint point, int direction) {
  final f = e.compile(x);
  final a = point.value?.evaluate() ?? 0;
  final xs = <double>[
    for (var k = 1; k <= 7; k++)
      point.isInfinite
          ? point.infinity * math.pow(10, k).toDouble()
          : a + direction * math.pow(10, -k).toDouble() * math.max(1, a.abs()),
  ];
  final ys = xs.map(f).toList();
  final finite = ys.where((y) => y.isFinite).toList();
  if (finite.length < 3) {
    if (ys.isNotEmpty && ys.last.isInfinite) {
      return InfiniteLimit(ys.last > 0 ? 1 : -1);
    }
    return const NoLimit('A função não está definida perto do ponto.');
  }

  final last = finite.sublist(finite.length - 3);
  final magnitudes = last.map((v) => v.abs()).toList();
  if (magnitudes[2] > 1e6 &&
      magnitudes[2] > magnitudes[1] * 2 &&
      magnitudes[1] > magnitudes[0]) {
    return InfiniteLimit(last[2] > 0 ? 1 : -1);
  }

  if (magnitudes[2] < 1e-6 && magnitudes[2] < magnitudes[0]) {
    return FiniteLimit(zero, approximate: true);
  }
  final scale = math.max(1.0, magnitudes[2]);
  final d1 = (last[1] - last[0]).abs();
  final d2 = (last[2] - last[1]).abs();
  if (d2 <= 1e-5 * scale && d2 <= d1 + 1e-12) {
    return FiniteLimit(
      Constant(Number.approximate(_round(last[2]))),
      approximate: true,
    );
  }
  return const NoLimit('Os valores não se aproximam de um número (oscilam).');
}

/// Arredonda para 7 algarismos significativos (limita o ruído numérico).
double _round(double v) {
  if (v == 0) return 0;
  final digits = 7 - (math.log(v.abs()) / math.ln10).ceil();
  final factor = math.pow(10, digits).toDouble();
  return (v * factor).roundToDouble() / factor;
}
