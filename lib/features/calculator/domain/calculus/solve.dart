import 'dart:math' as math;

import '../expression/expression.dart';

/// Raízes reais de f(x) = 0.
class SolveOutcome {
  const SolveOutcome({
    required this.roots,
    required this.steps,
    this.approximate = false,
    this.complexRoots = const [],
    this.truncated = false,
  });

  /// Raízes reais em ordem crescente (exatas quando possível).
  final List<Expression> roots;
  final List<String> steps;

  /// Alguma raiz veio da busca numérica.
  final bool approximate;

  /// Raízes complexas de uma quadrática com Δ < 0, já formatadas.
  final List<String> complexRoots;

  /// A busca numérica achou raízes demais (função periódica): só as mais
  /// próximas de zero foram mantidas.
  final bool truncated;
}

SolveOutcome solveEquation(Expression f, String x) {
  final steps = <String>[];
  final poly = polynomialCoefficients(f, x);
  if (poly != null && poly.isNotEmpty) {
    final degree = poly.keys.reduce(math.max);
    if (degree <= 2 || _rationalCoefficients(poly)) {
      return _polynomial(poly, degree, x, steps);
    }
  }
  return _numeric(f, x, steps);
}

bool _rationalCoefficients(Map<int, Expression> poly) =>
    poly.values.every((c) => c is Constant && c.value.isExact);

Expression _coef(Map<int, Expression> p, int k) => p[k] ?? zero;

SolveOutcome _polynomial(
  Map<int, Expression> poly,
  int degree,
  String x,
  List<String> steps,
) {
  final X = Variable(x);
  if (degree == 1) {
    final a = _coef(poly, 1);
    final b = _coef(poly, 0);
    steps.add('Equação do 1º grau ax + b = 0, com a = $a e b = $b: x = −b/a.');
    return SolveOutcome(roots: [simplify(neg(div(b, a)))], steps: steps);
  }
  if (degree == 2) {
    return _quadratic(_coef(poly, 2), _coef(poly, 1), _coef(poly, 0), steps);
  }

  // Grau ≥ 3 com coeficientes racionais: candidatos p/q (teorema das raízes
  // racionais), deflação por Briot-Ruffini e, no fim, fórmula ou numérico.
  var coefficients = [
    for (var k = degree; k >= 0; k--) (_coef(poly, k) as Constant).value,
  ];
  final roots = <Expression>[];

  // Raiz 0 com multiplicidade.
  while (coefficients.length > 1 && coefficients.last.isZero) {
    coefficients = coefficients.sublist(0, coefficients.length - 1);
    roots.add(zero);
  }
  final candidates = _rationalCandidates(coefficients);
  if (candidates.isNotEmpty) {
    steps.add(
      'Teorema das raízes racionais: testando os candidatos ±p/q '
      '(p divide o termo independente e q, o coeficiente líder).',
    );
  }
  var changed = true;
  while (changed && coefficients.length > 3) {
    changed = false;
    for (final r in candidates) {
      final (quotient, remainder) = _ruffini(coefficients, r);
      if (remainder.isZero) {
        roots.add(Constant(r));
        steps.add(
          'x = ${formatNumber(r)} é raiz; dividindo por (x − ${formatNumber(r)}).',
        );
        coefficients = quotient;
        changed = true;
        break;
      }
    }
  }

  final remaining = coefficients.length - 1;
  final rest = <int, Expression>{
    for (var i = 0; i < coefficients.length; i++)
      remaining - i: Constant(coefficients[i]),
  }..removeWhere((_, c) => isNumber(c, 0));

  if (remaining <= 2 && remaining >= 1) {
    final sub = _polynomial(rest, remaining, x, steps);
    return SolveOutcome(
      roots: _sorted([...roots, ...sub.roots]),
      steps: steps,
      complexRoots: sub.complexRoots,
    );
  }
  if (remaining == 0) {
    return SolveOutcome(roots: _sorted(roots), steps: steps);
  }

  // Sobrou um fator sem raízes racionais: numérico.
  Expression restPoly = add([
    for (final e in rest.entries) mul([e.value, pow(X, number(e.key))]),
  ]);
  final numeric = _numeric(restPoly, x, steps);
  return SolveOutcome(
    roots: _sorted([...roots, ...numeric.roots]),
    steps: steps,
    approximate: numeric.approximate,
  );
}

List<Expression> _sorted(List<Expression> roots) {
  final unique = <String, Expression>{};
  for (final r in roots) {
    unique[r.key] = r;
  }
  return unique.values.toList()
    ..sort((a, b) => a.evaluate().compareTo(b.evaluate()));
}

SolveOutcome _quadratic(
  Expression a,
  Expression b,
  Expression c,
  List<String> steps,
) {
  final delta = simplify(sub(pow(b, two), mul([number(4), a, c])));
  final d = delta.evaluate();
  steps.add('Equação do 2º grau: a = $a, b = $b, c = $c.');
  steps.add(
    'Δ = b² − 4ac = $delta${delta is Constant ? '' : ' ≈ ${formatDecimal(d)}'}.',
  );
  if (d < 0) {
    steps.add('Δ < 0: não há raízes reais.');
    final re = simplify(div(neg(b), mul([two, a])));
    final im = simplify(
      div(sqrt(neg(delta)), call(MathFunction.abs, mul([two, a]))),
    );
    return SolveOutcome(
      roots: const [],
      steps: steps,
      complexRoots: [
        for (final sign in const ['+', minusSign])
          '${isNumber(re, 0) ? (sign == '+' ? '' : minusSign) : '$re $sign '}'
              '${isNumber(im, 1) ? '' : im}i',
      ],
    );
  }
  if (d == 0) {
    steps.add('Δ = 0: uma raiz dupla, x = −b/(2a).');
    return SolveOutcome(
      roots: [
        simplify(div(neg(b), mul([two, a]))),
      ],
      steps: steps,
    );
  }
  steps.add('Δ > 0: duas raízes reais, x = (−b ± √Δ)/(2a).');
  final root = sqrt(delta);
  return SolveOutcome(
    roots: _sorted([
      tidy(div(add([neg(b), root]), mul([two, a]))),
      tidy(div(sub(neg(b), root), mul([two, a]))),
    ]),
    steps: steps,
  );
}

/// Divisão de Briot-Ruffini por (x − r): (quociente, resto).
(List<Number>, Number) _ruffini(List<Number> coefficients, Number r) {
  final out = <Number>[];
  var acc = Number.zero;
  for (final c in coefficients) {
    acc = acc * r + c;
    out.add(acc);
  }
  final remainder = out.removeLast();
  return (out, remainder);
}

List<Number> _rationalCandidates(List<Number> coefficients) {
  // Coeficientes inteiros: multiplica pelo MMC dos denominadores.
  var lcm = BigInt.one;
  for (final c in coefficients) {
    final q = (c as Rational).denominator;
    lcm = lcm * q ~/ lcm.gcd(q);
  }
  final ints = [
    for (final c in coefficients)
      (c as Rational).numerator * (lcm ~/ c.denominator),
  ];
  final leading = ints.first.abs();
  final constant = ints.last.abs();
  if (constant == BigInt.zero ||
      leading > BigInt.from(100000) ||
      constant > BigInt.from(100000)) {
    return const [];
  }
  List<int> divisors(int n) => [
    for (var d = 1; d <= n; d++)
      if (n % d == 0) d,
  ];
  final out = <String, Number>{};
  for (final p in divisors(constant.toInt())) {
    for (final q in divisors(leading.toInt())) {
      for (final s in const [1, -1]) {
        final r = Number.fraction(BigInt.from(s * p), BigInt.from(q));
        out[r.toString()] = r;
      }
    }
  }
  return out.values.toList()..sort((a, b) => a.abs().compareTo(b.abs()));
}

/// Busca numérica em [−100, 100]: troca de sinal + bissecção.
SolveOutcome _numeric(Expression f, String x, List<String> steps) {
  steps.add(
    'Sem fórmula fechada: busca numérica de raízes em [−100, 100] '
    '(troca de sinal + bissecção).',
  );
  final g = simplify(f).compile(x);
  const lo = -100.0;
  const hi = 100.0;
  const n = 40000;
  final found = <double>[];

  void addRoot(double r) {
    if (found.every((s) => (s - r).abs() > 1e-7 * math.max(1, r.abs()))) {
      found.add(r);
    }
  }

  var x0 = lo;
  var y0 = g(x0);
  for (var i = 1; i <= n; i++) {
    final x1 = lo + (hi - lo) * i / n;
    final y1 = g(x1);
    if (y0 == 0) {
      addRoot(x0);
    } else if (y0.isFinite && y1.isFinite && y0.sign != y1.sign && y1 != 0) {
      final r = _bisect(g, x0, x1);
      // Troca de sinal num polo (1/x em 0) não é raiz.
      if (g(r).abs() < 1e-6) addRoot(r);
    }
    x0 = x1;
    y0 = y1;
  }
  if (y0 == 0) addRoot(x0);

  var truncated = false;
  if (found.length > 10) {
    found.sort((a, b) => a.abs().compareTo(b.abs()));
    found.removeRange(10, found.length);
    truncated = true;
    steps.add(
      'Há muitas raízes (a função parece periódica): mostrando as 10 '
      'mais próximas de zero.',
    );
  }
  found.sort();

  var approximate = false;
  final roots = <Expression>[];
  for (final r in found) {
    final exact = _recognize(f, x, r);
    if (exact == null) approximate = true;
    roots.add(exact ?? Constant(Number.approximate(_round(r))));
  }
  return SolveOutcome(
    roots: roots,
    steps: steps,
    approximate: approximate,
    truncated: truncated,
  );
}

double _bisect(double Function(double) g, double a, double b) {
  var fa = g(a);
  for (var i = 0; i < 200; i++) {
    final m = (a + b) / 2;
    final fm = g(m);
    if (fm == 0 || (b - a).abs() < 1e-15 * math.max(1, m.abs())) return m;
    if (fa.sign == fm.sign) {
      a = m;
      fa = fm;
    } else {
      b = m;
    }
  }
  return (a + b) / 2;
}

/// Tenta reconhecer a raiz numérica como valor exato (inteiro, fração
/// simples, múltiplo de π, √n) e confirma substituindo na equação.
Expression? _recognize(Expression f, String x, double r) {
  final candidates = <Expression>[];
  for (final q in const [1, 2, 3, 4, 6]) {
    final p = (r * q).round();
    if ((p / q - r).abs() < 1e-8) {
      candidates.add(Constant(Number.fraction(BigInt.from(p), BigInt.from(q))));
    }
    final k = (r / math.pi * q).round();
    if (k != 0 && (k * math.pi / q - r).abs() < 1e-8) {
      candidates.add(
        mul([
          Constant(Number.fraction(BigInt.from(k), BigInt.from(q))),
          NamedConstant.pi,
        ]),
      );
    }
  }
  // √n e ∛n.
  for (final k in const [2, 3]) {
    final power = math.pow(r.abs(), k).round();
    if (power > 0 &&
        (math.pow(power, 1 / k) - r.abs()).abs() <
            1e-9 * math.max(1, r.abs())) {
      final root = pow(
        number(power),
        Constant(Number.fraction(BigInt.one, BigInt.from(k))),
      );
      candidates.add(r < 0 ? neg(root) : root);
    }
  }
  for (final c in candidates) {
    final value = simplify(substitute(f, x, c));
    if (isNumber(value, 0)) return simplify(c);
    // Valores que a simplificação não zera (cos(π/2)·algo…): confere com
    // precisão de máquina.
    final v = value.evaluate();
    if (v.isFinite && v.abs() < 1e-12) return simplify(c);
  }
  return null;
}

double _round(double v) {
  if (v == 0) return 0;
  final digits = 10 - (math.log(v.abs()) / math.ln10).ceil();
  final factor = math.pow(10, digits).toDouble();
  return (v * factor).roundToDouble() / factor;
}
