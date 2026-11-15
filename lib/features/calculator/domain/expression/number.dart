import 'dart:math' as math;

/// Número da calculadora: racional exato (p/q) ou aproximação em ponto
/// flutuante.
///
/// Literais como `0,1` e operações entre racionais continuam exatas (por
/// isso ∫x² dx sai `x³/3` e não `0,3333…·x³`). Basta um operando
/// aproximado — ou uma operação sem resultado racional, como √2 em decimal —
/// para o resultado virar aproximado, e a calculadora avisa isso ao usuário.
sealed class Number implements Comparable<Number> {
  const Number();

  factory Number.integer(int value) =>
      Rational._(BigInt.from(value), BigInt.one);

  factory Number.fraction(BigInt numerator, BigInt denominator) =>
      Rational.normalize(numerator, denominator);

  factory Number.approximate(double value) => Approximate(value);

  static final zero = Number.integer(0);
  static final one = Number.integer(1);
  static final minusOne = Number.integer(-1);

  double toDouble();

  bool get isExact;
  bool get isZero;
  bool get isOne;
  bool get isNegative;

  /// Inteiro exato (racional com denominador 1).
  bool get isInteger;

  Number operator +(Number other);
  Number operator -(Number other) => this + (-other);
  Number operator *(Number other);
  Number operator /(Number other);
  Number operator -();

  /// Potência. Exata quando possível: expoente inteiro (até um limite de
  /// tamanho) ou raiz exata (`4^(1/2) = 2`, `8^(1/3) = 2`). Devolve `null`
  /// quando o resultado exato não é racional (`2^(1/2)`): quem chama decide
  /// se mantém a forma simbólica.
  Number? exactPow(Number exponent);

  Number abs() => isNegative ? -this : this;

  @override
  int compareTo(Number other) => toDouble().compareTo(other.toDouble());
}

/// p/q com q > 0 e mdc(p, q) = 1.
final class Rational extends Number {
  const Rational._(this.numerator, this.denominator);

  factory Rational.normalize(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('Denominador zero');
    }
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final g = numerator.gcd(denominator);
    if (g > BigInt.one) {
      numerator ~/= g;
      denominator ~/= g;
    }
    return Rational._(numerator, denominator);
  }

  final BigInt numerator;
  final BigInt denominator;

  /// Acima disto (em bits), a fração vira aproximação: evita números
  /// gigantes em potências como 7^500.
  static const _maxBits = 256;

  @override
  double toDouble() => numerator / denominator;

  @override
  bool get isExact => true;
  @override
  bool get isZero => numerator == BigInt.zero;
  @override
  bool get isOne => numerator == BigInt.one && denominator == BigInt.one;
  @override
  bool get isNegative => numerator.isNegative;
  @override
  bool get isInteger => denominator == BigInt.one;

  Number _checked(BigInt p, BigInt q) {
    if (p.bitLength > _maxBits || q.bitLength > _maxBits) {
      return Approximate(p / q);
    }
    return Rational.normalize(p, q);
  }

  @override
  Number operator +(Number other) => switch (other) {
    Rational(:final numerator, :final denominator) => _checked(
      this.numerator * denominator + numerator * this.denominator,
      this.denominator * denominator,
    ),
    Approximate(:final value) => Approximate(toDouble() + value),
  };

  @override
  Number operator *(Number other) => switch (other) {
    Rational(:final numerator, :final denominator) => _checked(
      this.numerator * numerator,
      this.denominator * denominator,
    ),
    Approximate(:final value) => Approximate(toDouble() * value),
  };

  @override
  Number operator /(Number other) => switch (other) {
    Rational(:final numerator, :final denominator) =>
      numerator == BigInt.zero
          ? Approximate(toDouble() / 0)
          : _checked(
              this.numerator * denominator,
              this.denominator * numerator,
            ),
    Approximate(:final value) => Approximate(toDouble() / value),
  };

  @override
  Number operator -() => Rational._(-numerator, denominator);

  @override
  Number? exactPow(Number exponent) {
    if (exponent is! Rational) return null;
    if (exponent.isZero) return Number.one;
    if (isZero) return exponent.isNegative ? null : Number.zero;

    // Expoente p/q: raiz q-ésima exata, depois potência p.
    final q = exponent.denominator;
    var base = this;
    if (q != BigInt.one) {
      if (q.bitLength > 16) return null;
      final n = q.toInt();
      if (numerator.isNegative && n.isEven) return null; // √ de negativo
      final rootNum = _exactRoot(numerator.abs(), n);
      final rootDen = _exactRoot(denominator, n);
      if (rootNum == null || rootDen == null) return null;
      base = Rational._(numerator.isNegative ? -rootNum : rootNum, rootDen);
    }

    final p = exponent.numerator;
    final bits = math.max(base.numerator.bitLength, base.denominator.bitLength);
    if (p.abs().bitLength > 16 || bits * p.abs().toInt() > _maxBits) {
      return null;
    }
    final e = p.abs().toInt();
    final num = base.numerator.pow(e);
    final den = base.denominator.pow(e);
    return p.isNegative
        ? Rational.normalize(den, num)
        : Rational.normalize(num, den);
  }

  /// Raiz n-ésima inteira exata de [value] ≥ 0, ou `null` se não existir.
  static BigInt? _exactRoot(BigInt value, int n) {
    if (value < BigInt.two) return value;
    // Estimativa em double, depois correção na vizinhança.
    final guess = math.pow(value.toDouble(), 1 / n).round();
    for (var d = -1; d <= 1; d++) {
      final candidate = BigInt.from(guess + d);
      if (candidate >= BigInt.zero && candidate.pow(n) == value) {
        return candidate;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}

final class Approximate extends Number {
  const Approximate(this.value);

  final double value;

  @override
  double toDouble() => value;

  @override
  bool get isExact => false;
  @override
  bool get isZero => value == 0;
  @override
  bool get isOne => value == 1;
  @override
  bool get isNegative => value < 0;
  @override
  bool get isInteger => false;

  @override
  Number operator +(Number other) => Approximate(value + other.toDouble());
  @override
  Number operator *(Number other) => Approximate(value * other.toDouble());
  @override
  Number operator /(Number other) => Approximate(value / other.toDouble());
  @override
  Number operator -() => Approximate(-value);

  @override
  Number? exactPow(Number exponent) =>
      Approximate(math.pow(value, exponent.toDouble()).toDouble());

  @override
  bool operator ==(Object other) =>
      other is Approximate && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}
