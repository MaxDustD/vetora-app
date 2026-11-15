import 'ast.dart';
import 'number.dart';

/// Polinômio de uma variável com coeficientes racionais exatos.
/// `coefficients[i]` é o coeficiente de xⁱ.
class Polynomial {
  Polynomial(List<Number> coefficients) : coefficients = _trim(coefficients);

  final List<Number> coefficients;

  static List<Number> _trim(List<Number> c) {
    final out = [...c];
    while (out.isNotEmpty && out.last.isZero) {
      out.removeLast();
    }
    return out;
  }

  int get degree => coefficients.length - 1;
  bool get isZero => coefficients.isEmpty;
  Number get leading => coefficients.last;

  /// Lê [e] como polinômio em [x]; `null` se não for (ou se algum
  /// coeficiente não for um racional exato).
  static Polynomial? fromExpression(Expression e, String x) {
    final map = polynomialCoefficients(e, x);
    if (map == null) return null;
    if (map.isEmpty) return Polynomial(const []);
    final degree = map.keys.reduce((a, b) => a > b ? a : b);
    final c = List<Number>.filled(degree + 1, Number.zero);
    for (final entry in map.entries) {
      final v = entry.value;
      if (v is! Constant || !v.value.isExact) return null;
      c[entry.key] = v.value;
    }
    return Polynomial(c);
  }

  Expression toExpression(String x) => add([
    for (var i = 0; i < coefficients.length; i++)
      mul([Constant(coefficients[i]), pow(Variable(x), number(i))]),
  ]);

  /// Divisão euclidiana: (quociente, resto).
  (Polynomial, Polynomial) divide(Polynomial divisor) {
    var remainder = [...coefficients];
    final quotient = List<Number>.filled(
      degree - divisor.degree + 1 < 0 ? 0 : degree - divisor.degree + 1,
      Number.zero,
    );
    while (Polynomial(remainder).degree >= divisor.degree &&
        !Polynomial(remainder).isZero) {
      remainder = Polynomial(remainder).coefficients;
      final shift = remainder.length - 1 - divisor.degree;
      final factor = remainder.last / divisor.leading;
      quotient[shift] = factor;
      for (var i = 0; i <= divisor.degree; i++) {
        remainder[shift + i] =
            remainder[shift + i] - factor * divisor.coefficients[i];
      }
      remainder = Polynomial(remainder).coefficients;
    }
    return (Polynomial(quotient), Polynomial(remainder));
  }

  /// Máximo divisor comum (mônico), pelo algoritmo de Euclides.
  static Polynomial gcd(Polynomial a, Polynomial b) {
    var x = a;
    var y = b;
    while (!y.isZero) {
      final (_, r) = x.divide(y);
      x = y;
      y = r;
    }
    if (x.isZero) return x;
    final lead = x.leading;
    return Polynomial([for (final c in x.coefficients) c / lead]);
  }
}

/// Coeficientes do polinômio (grau → coeficiente), ou `null` se [e] não for
/// polinomial em [x] com coeficientes constantes.
Map<int, Expression>? polynomialCoefficients(Expression e, String x) {
  final expanded = expand(simplify(e));
  final terms = expanded is Sum ? expanded.terms : [expanded];
  final out = <int, Expression>{};
  for (final t in terms) {
    final factors = t is Product ? t.factors : [t];
    var degree = 0;
    final coefficient = <Expression>[];
    for (final f in factors) {
      if (!f.dependsOn(x)) {
        coefficient.add(f);
      } else if (f is Variable) {
        degree += 1;
      } else if (f is Power &&
          f.base is Variable &&
          f.exponent is Constant &&
          (f.exponent as Constant).value.isInteger &&
          !(f.exponent as Constant).value.isNegative) {
        degree += (f.exponent as Constant).value.toDouble().toInt();
      } else {
        return null;
      }
    }
    out[degree] = add([out[degree] ?? zero, mul(coefficient)]);
  }
  out.removeWhere((_, c) => isNumber(c, 0));
  return out;
}

/// Cancela fatores comuns de uma fração de polinômios em uma variável:
/// `(x² − 1)/(x − 1)` → `x + 1`. Devolve [e] se não se aplicar.
Expression cancelRational(Expression e) {
  final vars = e.variables;
  if (vars.length != 1) return e;
  final x = vars.single;
  final factors = e is Product ? e.factors : [e];
  final top = <Expression>[];
  final bottom = <Expression>[];
  for (final f in factors) {
    if (f is Power &&
        f.exponent is Constant &&
        (f.exponent as Constant).value.isNegative) {
      bottom.add(pow(f.base, neg(f.exponent)));
    } else {
      top.add(f);
    }
  }
  if (bottom.isEmpty) return e;
  final n = Polynomial.fromExpression(mul(top), x);
  final d = Polynomial.fromExpression(mul(bottom), x);
  if (n == null || d == null || d.isZero || d.degree < 1) return e;
  final g = Polynomial.gcd(n, d);
  if (g.degree < 1) return e;
  final (nq, _) = n.divide(g);
  final (dq, _) = d.divide(g);
  return mul([nq.toExpression(x), pow(dq.toExpression(x), minusOne)]);
}

/// Forma de exibição: a mais curta entre a simplificada, a com denominador
/// comum e a com fatores comuns cancelados.
Expression tidy(Expression e) {
  final s = simplify(e);
  var best = s;
  void consider(Expression candidate) {
    if (candidate.toString().length < best.toString().length) best = candidate;
  }

  final t = together(s);
  consider(t);
  consider(cancelRational(t));
  return best;
}
