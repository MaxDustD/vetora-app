import 'dart:math' as math;

import '../expression/expression.dart';
import 'derivative.dart';

/// Técnicas de integração, com o texto mostrado nos passos.
enum IntegrationTechnique {
  linearity('Linearidade: ∫(a·f + b·g) = a∫f + b∫g'),
  table('Integrais imediatas (tabela)'),
  linearSubstitution('Substituição linear: ∫f(ax + b) dx = F(ax + b)/a'),
  substitution('Substituição: u = g(x), du = g\'(x) dx'),
  byParts('Por partes: ∫u dv = u·v − ∫v du'),
  expansion('Expandindo o integrando'),
  trigonometricIdentity(
    'Identidades trigonométricas: sen²u + cos²u = 1, sen²u = (1 − cos 2u)/2, …',
  );

  const IntegrationTechnique(this.description);

  final String description;
}

/// Primitiva de [f] em relação a [variable] (sem a constante C), ou `null`
/// se nenhuma técnica conhecida funcionar.
///
/// Toda primitiva encontrada é conferida derivando-a numericamente em
/// vários pontos: se F' não bater com f, o resultado é descartado. Assim,
/// um erro de simplificação nunca vira uma resposta errada na tela.
Expression? antiderivative(
  Expression f,
  String variable, [
  Set<IntegrationTechnique>? techniques,
]) {
  final used = <IntegrationTechnique>{};
  final integrand = simplify(f);
  final result = _Integrator(variable, used).integrate(integrand, 0);
  if (result == null) return null;
  final tidy = simplify(result);
  if (!_verify(tidy, integrand, variable)) return null;
  techniques?.addAll(used);
  return tidy;
}

class _Integrator {
  _Integrator(this.x, this.used);

  final String x;
  final Set<IntegrationTechnique> used;
  static const _maxDepth = 6;
  var _counter = 0;

  Variable get _x => Variable(x);
  bool _dep(Expression e) => e.dependsOn(x);

  Expression? integrate(Expression e, int depth) {
    if (depth > _maxDepth) return null;
    if (!_dep(e)) return mul([e, _x]);

    if (e is Sum) {
      used.add(IntegrationTechnique.linearity);
      final parts = <Expression>[];
      for (final t in e.terms) {
        final r = integrate(t, depth);
        if (r == null) return null;
        parts.add(r);
      }
      return add(parts);
    }

    if (e is Product) {
      final constants = e.factors.where((f) => !_dep(f)).toList();
      if (constants.isNotEmpty) {
        used.add(IntegrationTechnique.linearity);
        final r = integrate(mul(e.factors.where(_dep).toList()), depth);
        return r == null ? null : mul([...constants, r]);
      }
    }

    return _table(e) ??
        _expTrig(e) ??
        _oddTrigPower(e, depth) ??
        _substitution(e, depth) ??
        _byParts(e, depth) ??
        _expanded(e, depth);
  }

  /// ∫ e^(au)·sen(bu) e ∫ e^(au)·cos(bu): por partes duas vezes a integral
  /// volta a aparecer; resolvendo a equação, sai a fórmula fechada.
  Expression? _expTrig(Expression e) {
    if (e is! Product || e.factors.length != 2) return null;
    final [p, q] = e.factors;
    final (power, trig) = p is Power ? (p, q) : (q, p);
    if (power is! Power || trig is! FunctionCall) return null;
    if (_dep(power.base) ||
        (trig.function != MathFunction.sin &&
            trig.function != MathFunction.cos)) {
      return null;
    }
    final a0 = _linearSlope(power.exponent);
    final b = _linearSlope(trig.argument);
    if (a0 == null || b == null) return null;
    final a = mul([a0, call(MathFunction.ln, power.base)]);
    final s = call(MathFunction.sin, trig.argument);
    final c = call(MathFunction.cos, trig.argument);
    final inner = trig.function == MathFunction.sin
        ? sub(mul([a, s]), mul([b, c]))
        : add([
            mul([a, c]),
            mul([b, s]),
          ]);
    used.add(IntegrationTechnique.byParts);
    return div(mul([power, inner]), add([pow(a, two), pow(b, two)]));
  }

  /// cosⁿu com n ímpar: cos·(1 − sen²)^((n−1)/2), e a substituição
  /// u = sen faz o resto (o mesmo para senⁿ).
  Expression? _oddTrigPower(Expression e, int depth) {
    if (e is! Power || e.base is! FunctionCall) return null;
    final f = e.base as FunctionCall;
    final n = e.exponent;
    if (n is! Constant || !n.value.isInteger || n.value.toDouble() < 3) {
      return null;
    }
    final k = n.value.toDouble().toInt();
    if (k.isEven) return null;
    final MathFunction other;
    if (f.function == MathFunction.cos) {
      other = MathFunction.sin;
    } else if (f.function == MathFunction.sin) {
      other = MathFunction.cos;
    } else {
      return null;
    }
    used.add(IntegrationTechnique.trigonometricIdentity);
    final rewritten = mul([
      f,
      pow(sub(one, pow(call(other, f.argument), two)), number((k - 1) ~/ 2)),
    ]);
    return _substitution(rewritten, depth);
  }

  /// u = a·x + b com a, b constantes (a ≠ 0): devolve a.
  Expression? _linearSlope(Expression u) {
    final d = derive(u, x);
    if (_dep(d) || isNumber(d, 0)) return null;
    return d;
  }

  Expression? _table(Expression e) {
    final r = _tableEntry(e);
    if (r != null) used.add(IntegrationTechnique.table);
    return r;
  }

  Expression? _tableEntry(Expression e) {
    // ∫ f(u) dx com u linear: F(u)/a.
    Expression? linear(Expression u, Expression Function() primitive) {
      final a = _linearSlope(u);
      if (a == null) return null;
      if (u is! Variable) used.add(IntegrationTechnique.linearSubstitution);
      return div(primitive(), a);
    }

    switch (e) {
      case Variable():
        return mul([half, pow(e, two)]);

      case Power(:final base, :final exponent)
          when _dep(base) && !_dep(exponent):
        // sec²u, cossec²u, sen²u, cos²u.
        if (base is FunctionCall && isNumber(exponent, 2)) {
          final u = base.argument;
          switch (base.function) {
            case MathFunction.sec:
              return linear(u, () => call(MathFunction.tan, u));
            case MathFunction.csc:
              return linear(u, () => neg(call(MathFunction.cot, u)));
            case MathFunction.sin:
              used.add(IntegrationTechnique.trigonometricIdentity);
              return linear(
                u,
                () => sub(
                  mul([half, u]),
                  mul([
                    Constant(Number.fraction(BigInt.one, BigInt.from(4))),
                    call(MathFunction.sin, mul([two, u])),
                  ]),
                ),
              );
            case MathFunction.cos:
              used.add(IntegrationTechnique.trigonometricIdentity);
              return linear(
                u,
                () => add([
                  mul([half, u]),
                  mul([
                    Constant(Number.fraction(BigInt.one, BigInt.from(4))),
                    call(MathFunction.sin, mul([two, u])),
                  ]),
                ]),
              );
            default:
              break;
          }
        }
        if (base is FunctionCall && isNumber(exponent, -2)) {
          final u = base.argument;
          if (base.function == MathFunction.cos) {
            return linear(u, () => call(MathFunction.tan, u));
          }
          if (base.function == MathFunction.sin) {
            return linear(u, () => neg(call(MathFunction.cot, u)));
          }
        }
        // 1/(p·x² + q) e 1/√(q − p·x²).
        final quadratic = _quadraticForm(base);
        if (quadratic != null) {
          final r = _quadratic(quadratic.$1, quadratic.$2, exponent);
          if (r != null) return r;
        }
        // uⁿ com u linear.
        if (isNumber(exponent, -1)) {
          return linear(
            base,
            () => call(MathFunction.ln, call(MathFunction.abs, base)),
          );
        }
        return linear(
          base,
          () => div(pow(base, add([exponent, one])), add([exponent, one])),
        );

      case Power(:final base, :final exponent)
          when !_dep(base) && _dep(exponent):
        // aᵘ com u linear (inclui eᵘ).
        return linear(
          exponent,
          () => div(pow(base, exponent), call(MathFunction.ln, base)),
        );

      case FunctionCall(:final function, :final argument):
        final u = argument;
        Expression f(MathFunction g, Expression a) => call(g, a);
        Expression ln(Expression a) => f(MathFunction.ln, a);
        Expression abs(Expression a) => f(MathFunction.abs, a);
        Expression? primitive() => switch (function) {
          MathFunction.sin => neg(f(MathFunction.cos, u)),
          MathFunction.cos => f(MathFunction.sin, u),
          MathFunction.tan => neg(ln(abs(f(MathFunction.cos, u)))),
          MathFunction.cot => ln(abs(f(MathFunction.sin, u))),
          MathFunction.sec => ln(
            abs(add([f(MathFunction.sec, u), f(MathFunction.tan, u)])),
          ),
          MathFunction.csc => neg(
            ln(abs(add([f(MathFunction.csc, u), f(MathFunction.cot, u)]))),
          ),
          MathFunction.sinh => f(MathFunction.cosh, u),
          MathFunction.cosh => f(MathFunction.sinh, u),
          MathFunction.tanh => ln(f(MathFunction.cosh, u)),
          MathFunction.ln => sub(mul([u, ln(u)]), u),
          MathFunction.log10 => div(sub(mul([u, ln(u)]), u), ln(number(10))),
          MathFunction.asin => add([
            mul([u, f(MathFunction.asin, u)]),
            sqrt(sub(one, pow(u, two))),
          ]),
          MathFunction.acos => sub(
            mul([u, f(MathFunction.acos, u)]),
            sqrt(sub(one, pow(u, two))),
          ),
          MathFunction.atan => sub(
            mul([u, f(MathFunction.atan, u)]),
            mul([
              half,
              ln(add([one, pow(u, two)])),
            ]),
          ),
          MathFunction.abs => mul([half, u, abs(u)]),
        };
        final p = primitive();
        return p == null ? null : linear(u, () => p);

      default:
        return null;
    }
  }

  /// p·x² + q (sem termo em x), com p e q constantes.
  (Expression, Expression)? _quadraticForm(Expression base) {
    if (base is! Sum) return null;
    Expression? p;
    final q = <Expression>[];
    for (final t in base.terms) {
      if (!_dep(t)) {
        q.add(t);
        continue;
      }
      final (c, literal) = splitCoefficient(t);
      if (literal is Power &&
          literal.base == _x &&
          isNumber(literal.exponent, 2) &&
          p == null) {
        p = Constant(c);
      } else {
        return null;
      }
    }
    if (p == null || q.isEmpty) return null;
    return (p, add(q));
  }

  Expression? _quadratic(Expression p, Expression q, Expression exponent) {
    final pv = p.evaluate();
    final qv = q.evaluate();
    if (!pv.isFinite || !qv.isFinite) return null;
    if (isNumber(exponent, -1)) {
      if (pv > 0 && qv > 0) {
        // 1/(px² + q) = arctg(x·√(p/q))/√(pq)
        return div(
          call(MathFunction.atan, mul([_x, sqrt(div(p, q))])),
          sqrt(mul([p, q])),
        );
      }
      if (pv * qv < 0) {
        // 1/(px² − r) = ln|(√p·x − √r)/(√p·x + √r)| / (2√(pr)), r = −q
        final pp = pv > 0 ? p : neg(p);
        final r = pv > 0 ? neg(q) : q;
        final sp = sqrt(pp);
        final sr = sqrt(r);
        final log = call(
          MathFunction.ln,
          call(
            MathFunction.abs,
            div(
              sub(mul([sp, _x]), sr),
              add([
                mul([sp, _x]),
                sr,
              ]),
            ),
          ),
        );
        final value = div(
          log,
          mul([
            two,
            sqrt(mul([pp, r])),
          ]),
        );
        return pv > 0 ? value : neg(value);
      }
    }
    if (exponent is Constant && exponent.value == (-half.value)) {
      if (pv < 0 && qv > 0) {
        // 1/√(q − |p|x²) = arcsen(x·√(|p|/q))/√|p|
        final ap = neg(p);
        return div(
          call(MathFunction.asin, mul([_x, sqrt(div(ap, q))])),
          sqrt(ap),
        );
      }
      if (pv > 0) {
        // 1/√(px² + q) = ln|√p·x + √(px² + q)|/√p
        return div(
          call(
            MathFunction.ln,
            call(
              MathFunction.abs,
              add([
                mul([sqrt(p), _x]),
                sqrt(
                  add([
                    mul([p, pow(_x, two)]),
                    q,
                  ]),
                ),
              ]),
            ),
          ),
          sqrt(p),
        );
      }
    }
    return null;
  }

  /// ∫ f(g(x))·g'(x) dx = F(g(x)): tenta cada subexpressão g do integrando.
  Expression? _substitution(Expression e, int depth) {
    final candidates = <String, Expression>{};
    void collect(Expression s) {
      switch (s) {
        case FunctionCall(:final argument):
          candidates[s.key] = s;
          candidates[argument.key] = argument;
          collect(argument);
        case Power(:final base, :final exponent):
          if (_dep(base)) candidates[base.key] = base;
          if (_dep(exponent)) candidates[exponent.key] = exponent;
          collect(base);
          collect(exponent);
        case Product(:final factors):
          factors.forEach(collect);
        case Sum(:final terms):
          candidates[s.key] = s;
          terms.forEach(collect);
        default:
          break;
      }
    }

    collect(e);
    final u = Variable('__u${_counter++}');
    for (final g in candidates.values) {
      if (!_dep(g) || g == _x || _linearSlope(g) != null) continue;
      final dg = derive(g, x);
      if (isNumber(dg, 0)) continue;
      final ratio = simplify(div(e, dg));
      final inU = replace(ratio, g, u);
      if (inU.dependsOn(x) || !inU.dependsOn(u.name)) continue;
      final f = _Integrator(u.name, used).integrate(inU, depth + 1);
      if (f == null) continue;
      used.add(IntegrationTechnique.substitution);
      return substitute(f, u.name, g);
    }
    return null;
  }

  /// Prioridade LIATE para escolher o "u" da integração por partes.
  int _liate(Expression f) => switch (f) {
    FunctionCall(function: MathFunction.ln || MathFunction.log10) => 5,
    FunctionCall(
      function: MathFunction.asin || MathFunction.acos || MathFunction.atan,
    ) =>
      4,
    Variable() => 3,
    Power(:final base, :final exponent)
        when base is Variable &&
            exponent is Constant &&
            exponent.value.isInteger &&
            !exponent.value.isNegative =>
      3,
    FunctionCall() => 2,
    Power() => 1,
    _ => 0,
  };

  Expression? _byParts(Expression e, int depth) {
    if (depth >= _maxDepth - 1) return null;
    final factors = e is Product ? e.factors : [e];
    // Um fator só: ∫ln x, ∫arctg x… já estão na tabela.
    if (factors.length < 2) return null;
    var best = 0;
    for (var i = 1; i < factors.length; i++) {
      if (_liate(factors[i]) > _liate(factors[best])) best = i;
    }
    final u = factors[best];
    final dv = mul([
      for (var i = 0; i < factors.length; i++)
        if (i != best) factors[i],
    ]);
    final v = integrate(dv, depth + 1);
    if (v == null) return null;
    final rest = integrate(simplify(mul([v, derive(u, x)])), depth + 1);
    if (rest == null) return null;
    used.add(IntegrationTechnique.byParts);
    return sub(mul([u, v]), rest);
  }

  Expression? _expanded(Expression e, int depth) {
    final ex = expand(e);
    if (ex == e) return null;
    used.add(IntegrationTechnique.expansion);
    return integrate(ex, depth + 1);
  }
}

/// Confere F' = f numericamente em vários pontos do domínio.
bool _verify(Expression primitive, Expression f, String x) {
  final fp = primitive.compile(x);
  final ff = f.compile(x);
  var checked = 0;
  for (final t in const [0.37, 1.31, 2.13, -0.71, 0.83, -1.9, 3.7, 0.05]) {
    final y = ff(t);
    if (!y.isFinite) continue;
    final h = 1e-5 * math.max(1, t.abs());
    final a = fp(t + h);
    final b = fp(t - h);
    if (!a.isFinite || !b.isFinite) continue;
    final derivative = (a - b) / (2 * h);
    if ((derivative - y).abs() > 1e-4 * math.max(1, y.abs())) return false;
    checked++;
  }
  return checked >= 2;
}

// ───────────────────────────── Numérica ─────────────────────────────

/// Resultado da integração numérica.
class NumericIntegral {
  const NumericIntegral(this.value, {required this.converged});

  final double value;
  final bool converged;
}

/// ∫ₐᵇ f(x) dx por Gauss–Kronrod (7–15 pontos) adaptativo.
///
/// Aceita extremos infinitos por mudança de variável. A regra não avalia
/// f nas pontas, então singularidades integráveis nelas (1/√x em 0)
/// funcionam.
NumericIntegral integrateNumerically(
  double Function(double) f,
  double a,
  double b,
) {
  if (a == b) return const NumericIntegral(0, converged: true);
  if (a > b) {
    final r = integrateNumerically(f, b, a);
    return NumericIntegral(-r.value, converged: r.converged);
  }
  if (a.isInfinite && b.isInfinite) {
    // x = t/(1 − t²), t ∈ (−1, 1)
    return _adaptive(
      (t) {
        final d = 1 - t * t;
        return f(t / d) * (1 + t * t) / (d * d);
      },
      -1,
      1,
    );
  }
  if (b.isInfinite) {
    // x = a + t/(1 − t), t ∈ [0, 1)
    return _adaptive((t) => f(a + t / (1 - t)) / ((1 - t) * (1 - t)), 0, 1);
  }
  if (a.isInfinite) {
    return _adaptive((t) => f(b - t / (1 - t)) / ((1 - t) * (1 - t)), 0, 1);
  }
  return _adaptive(f, a, b);
}

const _xgk = [
  0.991455371120812639206854697526329,
  0.949107912342758524526189684047851,
  0.864864423359769072789712788640926,
  0.741531185599394439863864773280788,
  0.586087235467691130294144845693013,
  0.405845151377397166906606412076961,
  0.207784955007898467600689403773245,
  0.000000000000000000000000000000000,
];
const _wgk = [
  0.022935322010529224963732008058970,
  0.063092092629978553290700663189204,
  0.104790010322250183839876322541518,
  0.140653259715525918745189590510238,
  0.169004726639267902826583426598550,
  0.190350578064785409913256402421014,
  0.204432940075298892414161999234649,
  0.209482141084727828012999174891714,
];
const _wg = [
  0.129484966168869693270611432679082,
  0.279705391489276667901467771423780,
  0.381830050505118944950369775488975,
  0.417959183673469387755102040816327,
];

(double, double) _kronrod(double Function(double) f, double a, double b) {
  final c = (a + b) / 2;
  final h = (b - a) / 2;
  final fc = f(c);
  var kronrod = fc * _wgk[7];
  var gauss = fc * _wg[3];
  for (var j = 0; j < 7; j++) {
    final dx = h * _xgk[j];
    final s = f(c - dx) + f(c + dx);
    kronrod += _wgk[j] * s;
    if (j.isOdd) gauss += _wg[j ~/ 2] * s;
  }
  return (kronrod * h, (kronrod - gauss).abs() * h);
}

NumericIntegral _adaptive(double Function(double) f, double a, double b) {
  final intervals = <(double, double, double, double)>[];
  final (v0, e0) = _kronrod(f, a, b);
  intervals.add((a, b, v0, e0));
  var total = v0;
  var error = e0;
  for (var i = 0; i < 400; i++) {
    if (!total.isFinite) return NumericIntegral(total, converged: false);
    if (error <= math.max(1e-10, 1e-10 * total.abs())) {
      return NumericIntegral(total, converged: true);
    }
    // Divide o intervalo de maior erro.
    var worst = 0;
    for (var j = 1; j < intervals.length; j++) {
      if (intervals[j].$4 > intervals[worst].$4) worst = j;
    }
    final (l, r, v, e) = intervals.removeAt(worst);
    final m = (l + r) / 2;
    final (v1, e1) = _kronrod(f, l, m);
    final (v2, e2) = _kronrod(f, m, r);
    intervals
      ..add((l, m, v1, e1))
      ..add((m, r, v2, e2));
    total += v1 + v2 - v;
    error += e1 + e2 - e;
  }
  return NumericIntegral(
    total,
    converged: error <= math.max(1e-6, 1e-6 * total.abs()),
  );
}
