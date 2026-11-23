import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/calculator/domain/calculator_engine.dart';

const engine = CalculatorEngine();

Matcher throwsCalculation(String fragment) => throwsA(
  isA<CalculationException>().having(
    (e) => e.message,
    'message',
    contains(fragment),
  ),
);

void main() {
  group('Calcular', () {
    test('resultado exato com decimal', () {
      final r = engine.evaluate('1/3 + 0,25');
      expect(r.result, '7/12');
      expect(r.decimal, '0,5833333333');
      expect(r.isApproximate, isFalse);
    });

    test('sem decimal quando não acrescenta nada', () {
      expect(engine.evaluate('2^10').decimal, isNull);
    });

    test('erros de domínio e de uso', () {
      expect(() => engine.evaluate('ln(-1)'), throwsCalculation('número real'));
      expect(
        () => engine.evaluate('1/0'),
        throwsCalculation('Divisão por zero'),
      );
      expect(() => engine.evaluate('2x'), throwsCalculation('variável “x”'));
    });
  });

  group('Derivar', () {
    test('regras básicas', () {
      expect(engine.derivative('x^3 - 2x').result, '3x² − 2');
      expect(engine.derivative('x²·sen(x)').result, 'x²·cos(x) + 2x·sen(x)');
      expect(engine.derivative('e^(2x)').result, '2e^(2x)');
      expect(engine.derivative('ln(x²+1)').result, '2x/(x² + 1)');
      expect(engine.derivative('x^x').result, 'x^x·(ln(x) + 1)');
    });

    test('quociente em uma única fração', () {
      expect(
        engine.derivative('(x²+1)/(x-1)').result,
        '(x² − 2x − 1)/(x − 1)²',
      );
    });

    test('ordem superior e valor no ponto', () {
      expect(engine.derivative('x^4', order: 2).result, '12x²');
      expect(engine.derivative('x^3', at: '2').result, '12');
    });

    test('passos citam as regras usadas', () {
      final steps = engine.derivative('sen(x²)').steps.join('\n');
      expect(steps, contains('Cadeia'));
      expect(steps, contains('Trigonométricas'));
    });
  });

  group('Integrar', () {
    test('indefinidas: tabela, substituição e por partes', () {
      expect(engine.integral('x^2').result, 'x³/3 + C');
      expect(engine.integral('1/x').result, 'ln|x| + C');
      expect(engine.integral('2x·cos(x²)').result, 'sen(x²) + C');
      expect(engine.integral('x·e^x').result, 'x·e^x − e^x + C');
      expect(engine.integral('x·ln(x)').result, 'x²·ln(x)/2 − x²/4 + C');
      expect(engine.integral('1/(x²+4)').result, 'arctg(x/2)/2 + C');
      expect(
        engine.integral('e^x·sen(x)').result,
        'e^x·(sen(x) − cos(x))/2 + C',
      );
    });

    test('sem primitiva elementar: pede limites', () {
      expect(
        () => engine.integral('e^(-x^2)'),
        throwsCalculation('Informe limites'),
      );
    });

    test('definidas exatas', () {
      expect(engine.integral('x^2', lower: '0', upper: '1').result, '1/3');
      expect(engine.integral('sen(x)', lower: '0', upper: 'pi').result, '2');
      expect(engine.integral('|x|', lower: '-1', upper: '2').result, '5/2');
    });

    test('impróprias convergentes e divergentes', () {
      expect(
        engine.integral('1/(1+x^2)', lower: '-inf', upper: 'inf').result,
        'π',
      );
      expect(engine.integral('e^(-x)', lower: '0', upper: '∞').result, '1');
      expect(engine.integral('1/√x', lower: '0', upper: '1').result, '2');
      expect(
        engine.integral('1/x', lower: '1', upper: '∞').result,
        contains('diverge'),
      );
      // Polo dentro do intervalo: F(1) − F(−1) daria −2, que está errado.
      expect(
        engine.integral('1/x^2', lower: '-1', upper: '1').result,
        'Diverge',
      );
    });

    test('numérica quando não há primitiva, marcada como aproximada', () {
      final r = engine.integral('e^(-x^2)', lower: '-inf', upper: 'inf');
      expect(r.result, '1,772453851'); // √π
      expect(r.isApproximate, isTrue);
    });

    test('exige os dois limites ou nenhum', () {
      expect(
        () => engine.integral('x', lower: '0'),
        throwsCalculation('dois limites'),
      );
    });
  });

  group('Limite', () {
    String lim(String f, String p, [LimitSide side = LimitSide.both]) =>
        engine.limit(f, point: p, side: side).result;

    test('substituição direta e L’Hôpital', () {
      expect(lim('x^2', '2'), '4');
      expect(lim('(x²-4)/(x-2)', '2'), '4');
      expect(lim('sen(x)/x', '0'), '1');
      expect(lim('(1-cos(x))/x²', '0'), '1/2');
      expect(lim('(e^x - 1)/x', '0'), '1');
    });

    test('no infinito', () {
      expect(lim('(3x²+1)/(x²-2)', '∞'), '3');
      expect(lim('(1+1/x)^x', 'inf'), 'e');
      expect(lim('arctg(x)', '∞'), 'π/2');
      expect(lim('x³/e^x', '∞'), '0');
      expect(lim('x - √(x²+1)', '∞'), '0'); // conjugado
      expect(lim('sen(x)/x', '∞'), '0'); // confronto
    });

    test('formas 0·∞, ∞ − ∞ e 0⁰', () {
      expect(lim('x·ln(x)', '0', LimitSide.right), '0');
      expect(lim('1/x - 1/sen(x)', '0'), '0');
      expect(lim('x^x', '0', LimitSide.right), '1');
    });

    test('infinitos, laterais e inexistentes', () {
      expect(lim('1/x', '0', LimitSide.right), '+∞');
      expect(lim('1/x²', '0'), '+∞');
      expect(lim('tg(x)', 'pi/2', LimitSide.left), '+∞');
      expect(lim('1/x', '0'), 'Não existe');
      expect(lim('|x|/x', '0'), 'Não existe');
      expect(lim('sen(1/x)', '0'), 'Não existe');
    });

    test('explica laterais diferentes', () {
      final steps = engine.limit('1/x', point: '0').steps.join('\n');
      expect(steps, contains('Pela esquerda: −∞'));
      expect(steps, contains('Pela direita: +∞'));
    });
  });

  group('Resolver', () {
    test('1º e 2º graus exatos', () {
      expect(engine.solve('2x + 3 = 7').result, 'x = 2');
      expect(engine.solve('x^2 - 5x + 6 = 0').result, 'x = 2  ou  x = 3');
      expect(engine.solve('x^2 = 2').result, 'x = −√2  ou  x = √2');
    });

    test('Δ < 0 mostra as raízes complexas nos passos', () {
      final r = engine.solve('x^2 + 1 = 0');
      expect(r.result, 'Sem raízes reais');
      expect(r.steps.last, contains('i'));
    });

    test('grau 3 pelas raízes racionais', () {
      expect(
        engine.solve('x^3 - 6x^2 + 11x - 6').result,
        'x = 1  ou  x = 2  ou  x = 3',
      );
    });

    test('numérica, reconhecendo valores exatos quando possível', () {
      expect(engine.solve('x^3 - 2 = 0').result, 'x = ∛2');
      final r = engine.solve('cos(x) = x');
      expect(r.result, 'x = 0,7390851332');
      expect(r.isApproximate, isTrue);
      expect(engine.solve('sen(x) = 0').result, contains('x = π'));
    });

    test('identidade e equação impossível', () {
      expect(engine.solve('x + 1 = x + 1').result, 'Verdadeira para todo x');
      expect(engine.solve('x = x + 1').result, 'Sem solução');
    });
  });

  group('Taylor', () {
    test('em torno de 0 e de outro ponto', () {
      expect(
        engine.taylor('e^x', order: 4).result,
        '1 + x + x²/2 + x³/6 + x⁴/24 + O(x⁵)',
      );
      expect(
        engine.taylor('sen(x)', order: 5).result,
        'x − x³/6 + x⁵/120 + O(x⁶)',
      );
      expect(
        engine.taylor('ln(x)', point: '1', order: 3).result,
        'x − 1 − (x − 1)²/2 + (x − 1)³/3 + O((x − 1)⁴)',
      );
    });

    test('ponto onde a função não é derivável', () {
      expect(() => engine.taylor('ln(x)'), throwsCalculation('derivável'));
    });
  });
}
