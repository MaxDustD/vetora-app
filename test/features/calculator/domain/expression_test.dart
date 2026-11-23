import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/calculator/domain/compiled_function.dart';
import 'package:vetora/features/calculator/domain/calculation_exception.dart';
import 'package:vetora/features/calculator/domain/expression/expression.dart';

String simp(String s) => tidy(parseExpression(s)).toString();
String raw(String s) => parseExpression(s).toString();

void main() {
  group('leitura', () {
    test('mostra a entrada como foi digitada, sem resolver', () {
      expect(raw('2+3*4'), '2 + 3·4');
      expect(raw('0,1+0,2'), '0,1 + 0,2');
      expect(raw('2x^2 - 3sen(x) + √(x+1)'), '2x² − 3sen(x) + √(x + 1)');
    });

    test('multiplicação implícita e funções sem parênteses', () {
      expect(raw('sen x cos x'), 'sen(x)·cos(x)');
      expect(raw('3(x+1)'), '3(x + 1)');
      expect(raw('senx'), 'sen(x)');
      expect(raw('2πx'), '2π·x');
    });

    test('precedência: −x² = −(x²) e potência associativa à direita', () {
      expect(parseExpression('-x^2').evaluate({'x': 3}), -9);
      expect(parseExpression('2^3^2').evaluate(), 512);
      expect(raw('1/2x'), 'x/2'); // da esquerda para a direita: (1/2)·x
    });

    test('sobrescritos, módulo e aliases em inglês', () {
      expect(parseExpression('x²·x³').evaluate({'x': 2}), 32);
      expect(parseExpression('|x - 5|').evaluate({'x': 2}), 3);
      expect(parseExpression('sin(pi/2) + sqrt(4)').evaluate(), 3);
    });

    test('erros com mensagem em português e posição', () {
      void expectError(String s, String fragment, int position) {
        expect(
          () => parseExpression(s),
          throwsA(
            isA<ExpressionException>()
                .having((e) => e.message, 'message', contains(fragment))
                .having((e) => e.position, 'position', position),
          ),
        );
      }

      expectError('2+', 'depois de “+”', 1);
      expectError('(x+1', 'não foi fechado', 0);
      expectError('x)', 'sem abertura', 1);
      expectError('3 # 4', 'Caractere inválido', 2);
      expectError('sen', 'argumento', 0);
    });
  });

  group('simplificação exata', () {
    test('frações e decimais exatos', () {
      expect(simp('1/3 + 1/6'), '1/2');
      expect(simp('0,1 + 0,2'), '3/10');
    });

    test('termos semelhantes, potências e distributiva numérica', () {
      expect(simp('x + x'), '2x');
      expect(simp('x²·x³'), 'x⁵');
      expect(simp('3 - (x - 1)'), '−x + 4');
    });

    test('raízes e valores notáveis', () {
      expect(simp('√8'), '2√2');
      expect(simp('√2·√8'), '4');
      expect(simp('sen(π/6)'), '1/2');
      expect(simp('cos(2π/3)'), '−1/2');
      expect(simp('tg(π/4)'), '1');
      expect(simp('ln(e^3)'), '3');
      expect(simp('log(1000)'), '3');
      expect(simp('e^(ln(x))'), 'x');
    });

    test('cancela fatores comuns de frações de polinômios', () {
      expect(simp('(x² − 1)/(x − 1)'), 'x + 1');
      expect(simp('(x² − 1)/(x − 1) + 2x − x'), '2x + 1');
    });

    test('expande produtos notáveis', () {
      expect(
        expand(parseExpression('(x+1)^3')).toString(),
        'x³ + 3x² + 3x + 1',
      );
    });
  });

  group('compileFunction (gráfico)', () {
    test('avalia rápido e sem lançar fora do domínio', () {
      expect(compileFunction('1/x')(0), double.infinity);
      expect(compileFunction('ln x')(-1), isNaN);
      expect(compileFunction('√x')(-1), isNaN);
      // Raiz cúbica real de negativos.
      expect(compileFunction('x^(1/3)')(-8), closeTo(-2, 1e-12));
    });

    test('entrada interpretada para a legenda', () {
      expect(compileFunction('2sen x + x²').input, '2sen(x) + x²');
    });

    test('rejeita outra variável e ∞', () {
      expect(
        () => compileFunction('x + y'),
        throwsA(
          isA<CalculationException>().having(
            (e) => e.message,
            'message',
            contains('“y”'),
          ),
        ),
      );
      expect(
        () => compileFunction('x + ∞'),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
