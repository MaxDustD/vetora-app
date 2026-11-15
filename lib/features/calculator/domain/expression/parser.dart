import 'ast.dart';
import 'number.dart';

/// Erro de digitação na expressão. [message] é escrita para o usuário e pode
/// ser exibida diretamente; [position] é o índice (a partir de 0) do
/// caractere com problema, para a interface destacá-lo.
class ExpressionException implements Exception {
  const ExpressionException(this.message, [this.position]);

  final String message;
  final int? position;

  @override
  String toString() => message;
}

/// Lê uma expressão digitada, como `2x² − 3sen(x) + √(x + 1)`.
///
/// A árvore devolvida é "crua" (como foi digitada, sem simplificar), o que
/// permite mostrar ao usuário como a entrada foi interpretada.
///
/// Aceita: `+ − * · × / ÷ ^`, sobrescritos (`x²`), multiplicação implícita
/// (`2x`, `3(x + 1)`, `x sen x`), vírgula ou ponto decimal, `π`/`pi`, `e`,
/// `∞`/`inf`, `|x|` e as funções de [_functions].
Expression parseExpression(String source) {
  final parser = _Parser(source);
  return parser.parseAll();
}

/// Lê uma equação `lado = lado`. Sem `=`, o lado direito é `null`.
(Expression, Expression?) parseEquation(String source) {
  final index = source.indexOf('=');
  if (index < 0) return (parseExpression(source), null);
  if (source.indexOf('=', index + 1) >= 0) {
    throw ExpressionException(
      'A equação tem mais de um sinal “=”.',
      source.indexOf('=', index + 1),
    );
  }
  final left = _Parser(source, end: index).parseAll(sideName: 'esquerdo');
  final right = _Parser(source, start: index + 1).parseAll(sideName: 'direito');
  return (left, right);
}

// ───────────────────────────── Nomes ─────────────────────────────

enum _Special { sqrt, cbrt, exp }

/// Nomes de função aceitos (português e inglês) e o que significam.
final Map<String, Object> _functions = {
  'sen': MathFunction.sin,
  'sin': MathFunction.sin,
  'cos': MathFunction.cos,
  'tg': MathFunction.tan,
  'tan': MathFunction.tan,
  'sec': MathFunction.sec,
  'cossec': MathFunction.csc,
  'cosec': MathFunction.csc,
  'csc': MathFunction.csc,
  'cotg': MathFunction.cot,
  'cotan': MathFunction.cot,
  'cot': MathFunction.cot,
  'arcsen': MathFunction.asin,
  'arcsin': MathFunction.asin,
  'asen': MathFunction.asin,
  'asin': MathFunction.asin,
  'arccos': MathFunction.acos,
  'acos': MathFunction.acos,
  'arctg': MathFunction.atan,
  'arctan': MathFunction.atan,
  'atg': MathFunction.atan,
  'atan': MathFunction.atan,
  'senh': MathFunction.sinh,
  'sinh': MathFunction.sinh,
  'cosh': MathFunction.cosh,
  'tgh': MathFunction.tanh,
  'tanh': MathFunction.tanh,
  'ln': MathFunction.ln,
  'log': MathFunction.log10,
  'abs': MathFunction.abs,
  'exp': _Special.exp,
  'raiz': _Special.sqrt,
  'sqrt': _Special.sqrt,
  'cbrt': _Special.cbrt,
};

final Map<String, Expression> _constants = {
  'pi': NamedConstant.pi,
  'π': NamedConstant.pi,
  'e': NamedConstant.e,
  'inf': NamedConstant.infinity,
  'infinito': NamedConstant.infinity,
  '∞': NamedConstant.infinity,
};

/// Do maior para o menor, para a leitura gulosa ("cosh" antes de "cos").
final List<String> _knownNames = [
  ..._functions.keys,
  ..._constants.keys.where((k) => k.length > 1),
]..sort((a, b) => b.length.compareTo(a.length));

// ───────────────────────────── Tokens ─────────────────────────────

enum _Kind { number, name, symbol, superscript, end }

class _Token {
  const _Token(this.kind, this.text, this.position, {this.value});

  final _Kind kind;
  final String text;
  final int position;
  final Number? value;

  bool isSymbol(String s) => kind == _Kind.symbol && text == s;
}

const _superscriptDigits = {
  '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4', //
  '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9', '⁻': '-',
};

const _symbolAliases = {
  '+': '+', '-': '-', '−': '-', '–': '-', '*': '*', '·': '*', '×': '*', //
  '/': '/', '÷': '/', '^': '^', '(': '(', ')': ')', '[': '(', ']': ')',
  '|': '|', '√': '√', '∛': '∛',
};

final _letter = RegExp(r'\p{L}', unicode: true);

List<_Token> _tokenize(String source, int start, int end) {
  final tokens = <_Token>[];
  var i = start;
  while (i < end) {
    final c = source[i];
    if (c.trim().isEmpty) {
      i++;
      continue;
    }

    // Número: dígitos com um separador decimal opcional (vírgula ou ponto).
    if ('0123456789'.contains(c) ||
        ((c == ',' || c == '.') &&
            i + 1 < end &&
            '0123456789'.contains(source[i + 1]))) {
      final begin = i;
      var seenSeparator = false;
      while (i < end) {
        final d = source[i];
        if ('0123456789'.contains(d)) {
          i++;
        } else if ((d == ',' || d == '.') && !seenSeparator) {
          seenSeparator = true;
          i++;
        } else {
          break;
        }
      }
      final text = source.substring(begin, i).replaceAll(',', '.');
      tokens.add(_Token(_Kind.number, text, begin, value: _parseDecimal(text)));
      continue;
    }

    if (_superscriptDigits.containsKey(c)) {
      final begin = i;
      final b = StringBuffer();
      while (i < end && _superscriptDigits.containsKey(source[i])) {
        b.write(_superscriptDigits[source[i]]);
        i++;
      }
      final text = b.toString();
      if (int.tryParse(text) == null) {
        throw ExpressionException(
          'Expoente sobrescrito inválido na posição ${begin + 1}.',
          begin,
        );
      }
      tokens.add(_Token(_Kind.superscript, text, begin));
      continue;
    }

    if (c == '∞') {
      tokens.add(_Token(_Kind.name, '∞', i));
      i++;
      continue;
    }

    if (_letter.hasMatch(c)) {
      final begin = i;
      while (i < end && _letter.hasMatch(source[i])) {
        i++;
      }
      tokens.addAll(_splitName(source.substring(begin, i), begin));
      continue;
    }

    final symbol = _symbolAliases[c];
    if (symbol != null) {
      tokens.add(_Token(_Kind.symbol, symbol, i));
      i++;
      continue;
    }

    if (c == '=') {
      throw ExpressionException(
        'O sinal “=” só pode aparecer em equações (posição ${i + 1}).',
        i,
      );
    }
    throw ExpressionException(
      'Caractere inválido “$c” na posição ${i + 1}.',
      i,
    );
  }
  tokens.add(_Token(_Kind.end, '', end));
  return tokens;
}

/// "senx" → sen, x; "xy" → x, y; "cosh" fica inteiro.
List<_Token> _splitName(String run, int begin) {
  final out = <_Token>[];
  var i = 0;
  final lower = run.toLowerCase();
  while (i < run.length) {
    String? match;
    for (final name in _knownNames) {
      if (lower.startsWith(name, i)) {
        match = name;
        break;
      }
    }
    final text = match ?? run[i];
    out.add(_Token(_Kind.name, match ?? text, begin + i));
    i += text.length;
  }
  return out;
}

Number _parseDecimal(String text) {
  final parts = text.split('.');
  final integer = parts[0].isEmpty ? '0' : parts[0];
  if (parts.length == 1) {
    return Number.fraction(BigInt.parse(integer), BigInt.one);
  }
  final fraction = parts[1];
  final scale = BigInt.from(10).pow(fraction.length);
  return Number.fraction(
    BigInt.parse(integer) * scale +
        BigInt.parse(fraction.isEmpty ? '0' : fraction),
    scale,
  );
}

// ───────────────────────────── Parser ─────────────────────────────

class _Parser {
  _Parser(this.source, {int start = 0, int? end})
    : _tokens = _tokenize(source, start, end ?? source.length),
      _start = start;

  final String source;
  final List<_Token> _tokens;
  final int _start;
  var _index = 0;

  /// Barras de módulo abertas: decide se um `|` abre ou fecha.
  var _absDepth = 0;

  _Token get _peek => _tokens[_index];
  _Token _next() => _tokens[_index++];

  Expression parseAll({String? sideName}) {
    if (_peek.kind == _Kind.end) {
      throw ExpressionException(
        sideName == null
            ? 'Digite uma expressão.'
            : 'O lado $sideName da equação está vazio.',
        _start,
      );
    }
    final e = _parseSum();
    final t = _peek;
    if (t.kind != _Kind.end) {
      if (t.isSymbol(')')) {
        throw ExpressionException(
          'Parêntese “)” sem abertura na posição ${t.position + 1}.',
          t.position,
        );
      }
      if (t.isSymbol('|')) {
        throw ExpressionException(
          'Barra de módulo “|” sem par na posição ${t.position + 1}.',
          t.position,
        );
      }
      throw ExpressionException(
        'Não entendi “${t.text}” na posição ${t.position + 1}.',
        t.position,
      );
    }
    return e;
  }

  Expression _parseSum() {
    final terms = <Expression>[_parseProduct()];
    while (_peek.isSymbol('+') || _peek.isSymbol('-')) {
      final op = _next();
      final term = _parseProduct(after: op);
      terms.add(op.text == '+' ? term : _negate(term));
    }
    return terms.length == 1 ? terms.single : Sum(terms);
  }

  Expression _parseProduct({_Token? after}) {
    final factors = <Expression>[_parseUnary(after: after)];
    while (true) {
      final t = _peek;
      if (t.isSymbol('*') || t.isSymbol('/')) {
        _next();
        final f = _parseUnary(after: t);
        factors.add(t.text == '*' ? f : Power(f, minusOne));
      } else if (_startsImplicitFactor(t)) {
        factors.add(_parseUnary(implicit: true));
      } else {
        break;
      }
    }
    return factors.length == 1 ? factors.single : Product(factors);
  }

  /// Um fator colado ao anterior (`2x`, `x(x + 1)`, `|x||y|`).
  bool _startsImplicitFactor(_Token t) {
    if (t.kind == _Kind.number || t.kind == _Kind.name) return true;
    if (t.isSymbol('(') || t.isSymbol('√') || t.isSymbol('∛')) return true;
    // Com um módulo aberto, `|` fecha; senão, abre um novo módulo.
    if (t.isSymbol('|')) return _absDepth == 0;
    return false;
  }

  Expression _parseUnary({_Token? after, bool implicit = false}) {
    final t = _peek;
    if (!implicit && (t.isSymbol('-') || t.isSymbol('+'))) {
      _next();
      final operand = _parseUnary(after: t);
      return t.text == '-' ? _negate(operand) : operand;
    }
    return _parsePower(after: after);
  }

  /// Potência associativa à direita: 2^3^2 = 2^(3^2).
  Expression _parsePower({_Token? after}) {
    final base = _parsePostfix(after: after);
    if (_peek.isSymbol('^')) {
      final op = _next();
      final exponent = _parseUnary(after: op);
      return Power(base, exponent);
    }
    return base;
  }

  Expression _parsePostfix({_Token? after}) {
    var e = _parsePrimary(after: after);
    while (_peek.kind == _Kind.superscript) {
      e = Power(e, Constant.integer(int.parse(_next().text)));
    }
    return e;
  }

  Expression _parsePrimary({_Token? after}) {
    final t = _peek;
    switch (t.kind) {
      case _Kind.number:
        _next();
        return Constant(
          t.value!,
          literal: source.substring(t.position, _literalEnd(t)),
        );
      case _Kind.name:
        _next();
        final function = _functions[t.text];
        if (function != null) return _parseFunction(t, function);
        final constant = _constants[t.text];
        if (constant != null) return constant;
        return Variable(t.text);
      case _Kind.symbol:
        if (t.text == '(') {
          _next();
          final inner = _parseInnerSum(t);
          if (!_peek.isSymbol(')')) {
            throw ExpressionException(
              'O parêntese aberto na posição ${t.position + 1} não foi '
              'fechado.',
              t.position,
            );
          }
          _next();
          return inner;
        }
        if (t.text == '|') {
          _next();
          _absDepth++;
          final inner = _parseInnerSum(t);
          if (!_peek.isSymbol('|')) {
            throw ExpressionException(
              'O módulo aberto na posição ${t.position + 1} não foi fechado.',
              t.position,
            );
          }
          _next();
          _absDepth--;
          return FunctionCall(MathFunction.abs, inner);
        }
        if (t.text == '√' || t.text == '∛') {
          _next();
          final radicand = _parsePostfix(after: t);
          return Power(
            radicand,
            Constant(
              Number.fraction(BigInt.one, BigInt.from(t.text == '√' ? 2 : 3)),
            ),
          );
        }
        if (t.text == ')') {
          throw ExpressionException(
            after == null
                ? 'Parêntese “)” sem abertura na posição ${t.position + 1}.'
                : 'Falta um valor antes de “)” (posição ${t.position + 1}).',
            t.position,
          );
        }
        throw _missingOperand(after, t);
      case _Kind.superscript:
        throw ExpressionException(
          'Expoente sem base na posição ${t.position + 1}.',
          t.position,
        );
      case _Kind.end:
        throw _missingOperand(after, t);
    }
  }

  /// Dentro de parênteses ou módulo, um `|` volta a poder abrir módulo
  /// novo apenas depois de um operador; o contador cuida disso.
  Expression _parseInnerSum(_Token opener) {
    if (_peek.kind == _Kind.end || _peek.isSymbol(')')) {
      throw ExpressionException(
        'Os parênteses na posição ${opener.position + 1} estão vazios.',
        opener.position,
      );
    }
    final saved = _absDepth;
    if (opener.isSymbol('(')) _absDepth = 0;
    final e = _parseSum();
    _absDepth = opener.isSymbol('(') ? saved : _absDepth;
    return e;
  }

  ExpressionException _missingOperand(_Token? after, _Token at) {
    if (after == null) {
      return ExpressionException(
        'Falta um número ou variável na posição ${at.position + 1}.',
        at.position,
      );
    }
    final op = switch (after.text) {
      '-' => '−',
      '*' => '×',
      _ => after.text,
    };
    return ExpressionException(
      'Falta um valor depois de “$op” (posição ${after.position + 1}).',
      after.position,
    );
  }

  /// `sen(x)`, `sen x`, `sen 2x`, `sen²(x)`, `√(x + 1)`.
  Expression _parseFunction(_Token name, Object function) {
    Expression? power;
    if (_peek.kind == _Kind.superscript) {
      power = Constant.integer(int.parse(_next().text));
    }

    final Expression argument;
    if (_peek.isSymbol('(')) {
      argument = _parsePrimary(after: name);
    } else if (_peek.kind == _Kind.number ||
        _peek.kind == _Kind.name ||
        _peek.isSymbol('|') ||
        _peek.isSymbol('√')) {
      // Sem parênteses, o argumento vai até o próximo operador ou função:
      // "sen 2x + 1" = sen(2x) + 1; "sen x cos x" = sen(x)·cos(x).
      final factors = <Expression>[_parsePower(after: name)];
      while ((_peek.kind == _Kind.number ||
              (_peek.kind == _Kind.name &&
                  !_functions.containsKey(_peek.text))) &&
          factors.isNotEmpty) {
        factors.add(_parsePower(after: name));
      }
      argument = factors.length == 1 ? factors.single : Product(factors);
    } else {
      throw ExpressionException(
        'Falta o argumento de “${name.text}” (posição ${name.position + 1}).',
        name.position,
      );
    }

    final Expression applied = switch (function) {
      MathFunction f => FunctionCall(f, argument),
      _Special.sqrt => Power(argument, half),
      _Special.cbrt => Power(
        argument,
        Constant(Number.fraction(BigInt.one, BigInt.from(3))),
      ),
      _Special.exp => Power(NamedConstant.e, argument),
      _ => throw StateError('função desconhecida'),
    };
    return power == null ? applied : Power(applied, power);
  }

  int _literalEnd(_Token t) {
    var i = t.position;
    while (i < source.length && '0123456789,.'.contains(source[i])) {
      i++;
    }
    return i;
  }

  Expression _negate(Expression e) {
    if (e is Constant) {
      final literal = e.literal;
      return Constant(-e.value, literal: literal == null ? null : '−$literal');
    }
    return Product([minusOne, e]);
  }
}
