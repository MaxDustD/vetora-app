import 'ast.dart';
import 'number.dart';

/// Sinal de menos tipográfico, o mesmo do material dos módulos.
const minusSign = '−';

const _superscripts = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', //
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
};

String superscript(String digits) =>
    digits.split('').map((c) => _superscripts[c] ?? c).join();

/// Decimal em pt-BR: vírgula decimal, até [significantDigits] algarismos
/// significativos, sem zeros à direita e com notação científica para
/// valores muito grandes ou muito pequenos (`1,5×10⁻⁸`).
String formatDecimal(double value, {int significantDigits = 10}) {
  if (value.isNaN) return 'indefinido';
  if (value.isInfinite) return value > 0 ? '∞' : '$minusSign∞';
  if (value == 0) return '0';

  final sign = value < 0 ? minusSign : '';
  final v = value.abs();

  if (v >= 1e12 || v < 1e-6) {
    final s = v.toStringAsExponential(significantDigits - 1);
    final [mantissa, exponent] = s.split('e');
    final e = int.parse(exponent);
    return '$sign${_trim(mantissa)}×10${superscript('$e')}';
  }
  var s = v.toStringAsPrecision(significantDigits);
  if (s.contains('e')) s = v.toString();
  return '$sign${_trim(s)}';
}

String _trim(String s) {
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

String formatNumber(Number n) => switch (n) {
  Rational(:final numerator, :final denominator) =>
    (numerator.isNegative ? minusSign : '') +
        (denominator == BigInt.one
            ? '${numerator.abs()}'
            : '${numerator.abs()}/$denominator'),
  Approximate(:final value) => formatDecimal(value),
};

/// Converte uma [Expression] em texto matemático legível.
///
/// Precedências: 1 soma, 2 produto/fração/negativo, 3 potência, 4 átomo.
/// Um filho só ganha parênteses quando a precedência dele é menor que a
/// exigida pelo contexto.
abstract final class ExpressionPrinter {
  static String format(Expression e) => _fmt(e, 0);

  static String _wrap(String s, int own, int context) =>
      own < context ? '($s)' : s;

  static String _fmt(Expression e, int context) {
    switch (e) {
      case Constant(:final value, :final literal):
        final s = literal ?? formatNumber(value);
        final own =
            value.isNegative ||
                (value is Rational && !value.isInteger) ||
                s.contains('×')
            ? 2
            : 4;
        return _wrap(s, own, context);
      case NamedConstant(:final kind):
        return kind.symbol;
      case Variable(:final name):
        return name;
      case Sum(:final terms):
        final b = StringBuffer();
        for (var i = 0; i < terms.length; i++) {
          final (negative, positive) = _negated(terms[i]);
          if (i == 0) {
            b.write(
              negative ? '$minusSign${_fmt(positive, 2)}' : _fmt(terms[i], 1),
            );
          } else {
            b.write(negative ? ' $minusSign ' : ' + ');
            b.write(_fmt(negative ? positive : terms[i], negative ? 2 : 1));
          }
        }
        return _wrap(b.toString(), 1, context);
      case Product():
        return _product(e, context);
      case Power(:final base, :final exponent):
        return _power(base, exponent, context);
      case FunctionCall(:final function, :final argument):
        if (function == MathFunction.abs) return '|${_fmt(argument, 0)}|';
        // ln|x| em vez de ln(|x|).
        if (argument is FunctionCall && argument.function == MathFunction.abs) {
          return '${function.symbol}${_fmt(argument, 0)}';
        }
        return '${function.symbol}(${_fmt(argument, 0)})';
    }
  }

  /// Se o termo começa com coeficiente negativo, devolve o termo positivo
  /// correspondente (para imprimir `a − b` em vez de `a + −b`).
  static (bool, Expression) _negated(Expression t) {
    if (t is Constant && t.value.isNegative) return (true, Constant(-t.value));
    if (t is Product && t.factors.isNotEmpty) {
      final first = t.factors.first;
      if (first is Constant && first.value.isNegative) {
        final c = -first.value;
        final rest = t.factors.sublist(1);
        if (c.isOne && c.isExact) {
          return (true, rest.length == 1 ? rest.single : Product(rest));
        }
        return (true, Product([Constant(c), ...rest]));
      }
    }
    return (false, t);
  }

  static void _flatten(Expression e, List<Expression> out) {
    if (e is Product) {
      for (final f in e.factors) {
        _flatten(f, out);
      }
    } else {
      out.add(e);
    }
  }

  static String _product(Product p, int context) {
    final factors = <Expression>[];
    _flatten(p, factors);

    var coefficient = Number.one;
    final numerator = <Expression>[];
    final denominator = <Expression>[];
    for (var i = 0; i < factors.length; i++) {
      final f = factors[i];
      // Só o primeiro número é coeficiente; os demais aparecem como foram
      // digitados ("3·4" não vira "12" na hora de mostrar a entrada).
      if (f is Constant && i == 0) {
        coefficient = f.value;
      } else if (f is Power &&
          f.exponent is Constant &&
          (f.exponent as Constant).value.isNegative) {
        final positive = -(f.exponent as Constant).value;
        if (positive.isOne && positive.isExact) {
          // 1/(2y) cru: os fatores do produto vão direto para o denominador.
          _flatten(f.base, denominator);
        } else {
          denominator.add(Power(f.base, Constant(positive)));
        }
      } else {
        numerator.add(f);
      }
    }

    final negative = coefficient.isNegative;
    coefficient = coefficient.abs();
    String? numCoef;
    String? denCoef;
    if (coefficient case Rational(:final numerator, :final denominator)) {
      if (numerator != BigInt.one) numCoef = '$numerator';
      if (denominator != BigInt.one) denCoef = '$denominator';
    } else {
      numCoef = formatNumber(coefficient);
    }

    final top = _join(numCoef, numerator);
    // Número digitado no denominador (1/(2y)) vira o coeficiente dele.
    if (denominator.isNotEmpty &&
        denominator.first is Constant &&
        denCoef == null) {
      denCoef = _fmt(denominator.removeAt(0), 3);
    }
    final bottom = denominator.isEmpty && denCoef == null
        ? null
        : _join(denCoef, denominator);

    var s = top.isEmpty ? '1' : top;
    if (bottom != null) {
      // Uma soma sozinha já sai entre parênteses de _fmt.
      final needsParens = denominator.length + (denCoef == null ? 0 : 1) > 1;
      s = '$s/${needsParens ? '($bottom)' : bottom}';
    }
    if (negative) s = '$minusSign$s';

    return _wrap(s, 2, context);
  }

  /// Junta coeficiente e fatores: número seguido de letra fica colado
  /// (`2x`, `3sen(x)`); entre fatores literais usa `·` (`x·sen(x)`).
  static String _join(String? coefficient, List<Expression> factors) {
    final b = StringBuffer(coefficient ?? '');
    for (final f in factors) {
      final s = _fmt(f, 3);
      if (b.isEmpty) {
        b.write(s);
        continue;
      }
      final previous = b.toString();
      final afterNumber =
          coefficient != null &&
          previous == coefficient &&
          !_startsWithDigit(s);
      if (afterNumber) {
        b.write(s);
      } else {
        b.write('·$s');
      }
    }
    return b.toString();
  }

  static bool _startsWithDigit(String s) =>
      s.isNotEmpty && '0123456789'.contains(s[0]);

  static bool _isSimpleAtom(Expression e) =>
      e is Variable ||
      e is NamedConstant ||
      (e is Constant &&
          e.value is Rational &&
          e.value.isInteger &&
          !e.value.isNegative);

  static String _power(Expression base, Expression exponent, int context) {
    if (exponent is Constant) {
      final v = exponent.value;
      if (v.isNegative) {
        return _product(Product([Power(base, exponent)]), context);
      }
      if (v case Rational(:final numerator, :final denominator)) {
        if (numerator == BigInt.one &&
            (denominator == BigInt.two || denominator == BigInt.from(3))) {
          final root = denominator == BigInt.two ? '√' : '∛';
          final inner = _isSimpleAtom(base)
              ? _fmt(base, 4)
              : '(${_fmt(base, 0)})';
          return '$root$inner';
        }
        if (denominator == BigInt.one) {
          final b = base is Power ? '(${_fmt(base, 0)})' : _fmt(base, 4);
          return '$b${superscript('$numerator')}';
        }
      }
    }
    final b = base is FunctionCall || base is Power
        ? '(${_fmt(base, 0)})'
        : _fmt(base, 4);
    final x = _fmt(exponent, 4);
    return _wrap('$b^$x', 3, context);
  }
}
