import '../expression/expression.dart';

/// Regras de derivação, com o texto mostrado nos passos da solução.
enum DerivativeRule {
  constant("Constante: (c)' = 0"),
  sum("Soma: (f + g)' = f' + g'"),
  constantMultiple("Múltiplo: (c·f)' = c·f'"),
  power("Potência: (uⁿ)' = n·uⁿ⁻¹·u'"),
  product("Produto: (f·g)' = f'·g + f·g'"),
  quotient("Quociente: (f/g)' = (f'·g − f·g')/g²"),
  exponential("Exponencial: (aᵘ)' = aᵘ·ln(a)·u'"),
  generalPower("Potência geral: (uᵛ)' = uᵛ·(v'·ln(u) + v·u'/u)"),
  logarithm("Logaritmo: (ln u)' = u'/u"),
  trigonometric(
    "Trigonométricas: (sen u)' = cos(u)·u', (cos u)' = −sen(u)·u', …",
  ),
  inverseTrigonometric("Trigonométricas inversas: (arctg u)' = u'/(1 + u²), …"),
  hyperbolic("Hiperbólicas: (senh u)' = cosh(u)·u', …"),
  absolute("Módulo: |u|' = u·u'/|u|"),
  chain("Cadeia: [f(g(x))]' = f'(g(x))·g'(x)");

  const DerivativeRule(this.description);

  final String description;
}

/// Derivada de [e] em relação a [variable], simplificada.
///
/// As regras aplicadas são acumuladas em [rules], na ordem em que aparecem.
Expression derive(Expression e, String variable, [Set<DerivativeRule>? rules]) {
  final used = rules ?? <DerivativeRule>{};
  return _Deriver(variable, used).d(e);
}

/// Derivada de ordem [order] (1 = primeira derivada).
Expression deriveN(
  Expression e,
  String variable,
  int order, [
  Set<DerivativeRule>? rules,
]) {
  var result = e;
  for (var i = 0; i < order; i++) {
    result = derive(result, variable, rules);
  }
  return result;
}

class _Deriver {
  _Deriver(this.x, this.rules);

  final String x;
  final Set<DerivativeRule> rules;

  bool _dep(Expression e) => e.dependsOn(x);

  /// Marca a regra da cadeia quando o argumento não é a própria variável.
  void _chain(Expression inner) {
    if (!(inner is Variable && inner.name == x)) {
      rules.add(DerivativeRule.chain);
    }
  }

  Expression d(Expression e) {
    if (!_dep(e)) {
      rules.add(DerivativeRule.constant);
      return zero;
    }
    switch (e) {
      case Variable():
        return one; // depende de x, logo é o próprio x
      case Sum(:final terms):
        rules.add(DerivativeRule.sum);
        return add([for (final t in terms) d(t)]);
      case Product(:final factors):
        return _product(factors);
      case Power(:final base, :final exponent):
        return _power(base, exponent);
      case FunctionCall(:final function, :final argument):
        return _function(function, argument);
      case Constant() || NamedConstant():
        return zero; // inalcançável: constantes não dependem de x
    }
  }

  Expression _product(List<Expression> factors) {
    final constants = factors.where((f) => !_dep(f)).toList();
    final variables = factors.where(_dep).toList();
    if (constants.isNotEmpty) rules.add(DerivativeRule.constantMultiple);
    if (variables.length == 1) {
      return mul([...constants, d(variables.single)]);
    }

    final hasDenominator = variables.any(
      (f) =>
          f is Power &&
          f.exponent is Constant &&
          (f.exponent as Constant).value.isNegative,
    );
    rules.add(
      hasDenominator ? DerivativeRule.quotient : DerivativeRule.product,
    );

    // (f₁·f₂·…·fₙ)' = Σ fᵢ'·Π(j≠i) fⱼ
    return mul([
      ...constants,
      add([
        for (var i = 0; i < variables.length; i++)
          mul([
            d(variables[i]),
            for (var j = 0; j < variables.length; j++)
              if (j != i) variables[j],
          ]),
      ]),
    ]);
  }

  Expression _power(Expression base, Expression exponent) {
    final baseVaries = _dep(base);
    final exponentVaries = _dep(exponent);

    if (baseVaries && !exponentVaries) {
      rules.add(DerivativeRule.power);
      _chain(base);
      return mul([exponent, pow(base, sub(exponent, one)), d(base)]);
    }
    if (!baseVaries && exponentVaries) {
      rules.add(DerivativeRule.exponential);
      _chain(exponent);
      return mul([
        pow(base, exponent),
        call(MathFunction.ln, base),
        d(exponent),
      ]);
    }
    rules.add(DerivativeRule.generalPower);
    return mul([
      pow(base, exponent),
      add([
        mul([d(exponent), call(MathFunction.ln, base)]),
        mul([exponent, d(base), pow(base, minusOne)]),
      ]),
    ]);
  }

  Expression _function(MathFunction f, Expression u) {
    _chain(u);
    final du = d(u);
    Expression c(MathFunction g) => call(g, u);

    final Expression outer;
    switch (f) {
      case MathFunction.sin:
        rules.add(DerivativeRule.trigonometric);
        outer = c(MathFunction.cos);
      case MathFunction.cos:
        rules.add(DerivativeRule.trigonometric);
        outer = neg(c(MathFunction.sin));
      case MathFunction.tan:
        rules.add(DerivativeRule.trigonometric);
        outer = pow(c(MathFunction.sec), two);
      case MathFunction.sec:
        rules.add(DerivativeRule.trigonometric);
        outer = mul([c(MathFunction.sec), c(MathFunction.tan)]);
      case MathFunction.csc:
        rules.add(DerivativeRule.trigonometric);
        outer = neg(mul([c(MathFunction.csc), c(MathFunction.cot)]));
      case MathFunction.cot:
        rules.add(DerivativeRule.trigonometric);
        outer = neg(pow(c(MathFunction.csc), two));
      case MathFunction.asin:
        rules.add(DerivativeRule.inverseTrigonometric);
        outer = pow(sub(one, pow(u, two)), neg(half));
      case MathFunction.acos:
        rules.add(DerivativeRule.inverseTrigonometric);
        outer = neg(pow(sub(one, pow(u, two)), neg(half)));
      case MathFunction.atan:
        rules.add(DerivativeRule.inverseTrigonometric);
        outer = pow(add([one, pow(u, two)]), minusOne);
      case MathFunction.sinh:
        rules.add(DerivativeRule.hyperbolic);
        outer = c(MathFunction.cosh);
      case MathFunction.cosh:
        rules.add(DerivativeRule.hyperbolic);
        outer = c(MathFunction.sinh);
      case MathFunction.tanh:
        rules.add(DerivativeRule.hyperbolic);
        outer = pow(c(MathFunction.cosh), number(-2));
      case MathFunction.ln:
        rules.add(DerivativeRule.logarithm);
        outer = pow(u, minusOne);
      case MathFunction.log10:
        rules.add(DerivativeRule.logarithm);
        outer = pow(mul([u, call(MathFunction.ln, number(10))]), minusOne);
      case MathFunction.abs:
        rules.add(DerivativeRule.absolute);
        outer = mul([u, pow(c(MathFunction.abs), minusOne)]);
    }
    return mul([outer, du]);
  }
}
