import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/calculator/graphing/domain/graph_viewport.dart';

void main() {
  const viewport = GraphViewport(xMin: -10, xMax: 10, yMin: -5, yMax: 5);

  group('conversões entre plano e tela', () {
    test('origem fica no centro e o y da tela cresce para baixo', () {
      expect(viewport.toScreenX(0, 200), 100);
      expect(viewport.toScreenY(0, 100), 50);
      expect(viewport.toScreenY(5, 100), 0);
      expect(viewport.toScreenY(-5, 100), 100);
    });

    test('ida e volta devolvem o mesmo ponto', () {
      expect(
        viewport.toWorldX(viewport.toScreenX(3.7, 320), 320),
        closeTo(3.7, 1e-9),
      );
      expect(
        viewport.toWorldY(viewport.toScreenY(-1.2, 240), 240),
        closeTo(-1.2, 1e-9),
      );
    });
  });

  test('arrastar desloca a janela sem mudar o tamanho', () {
    final moved = viewport.panBy(2, -1);
    expect(moved, const GraphViewport(xMin: -8, xMax: 12, yMin: -6, yMax: 4));
  });

  group('zoom', () {
    test('aproximar no centro reduz a janela pela metade', () {
      final zoomed = viewport.zoom(2);
      expect(
        zoomed,
        const GraphViewport(xMin: -5, xMax: 5, yMin: -2.5, yMax: 2.5),
      );
    });

    test('mantém o ponto focal parado', () {
      final zoomed = viewport.zoom(4, focusX: 6, focusY: 2);
      // O ponto (6, 2) continua na mesma fração da janela.
      expect((6 - zoomed.xMin) / zoomed.width, closeTo(0.8, 1e-9));
      expect((2 - zoomed.yMin) / zoomed.height, closeTo(0.7, 1e-9));
    });

    test('respeita os limites de zoom', () {
      expect(viewport.zoom(1e12).width, GraphViewport.minSpan);
      expect(viewport.zoom(1e-12).width, GraphViewport.maxSpan);
    });
  });

  test('proporção da tela deixa unidades de x e y iguais', () {
    final square = viewport.withAspectRatio(400, 200);
    expect(square.width, 20);
    expect(square.height, 10);
    expect((square.yMin + square.yMax) / 2, 0);
  });

  test('passo das marcas é 1, 2 ou 5 × 10ⁿ', () {
    expect(niceTickStep(20, targetTicks: 10), 2);
    expect(niceTickStep(10, targetTicks: 10), 1);
    expect(niceTickStep(50, targetTicks: 10), 5);
    expect(niceTickStep(0.03, targetTicks: 6), 0.005);
    expect(niceTickStep(900, targetTicks: 6), 200);
  });

  group('formatação', () {
    test('números dos eixos usam vírgula e as casas do passo', () {
      expect(formatAxisValue(1.5, 0.5), '1,5');
      expect(formatAxisValue(4, 2), '4');
      expect(formatAxisValue(-0.25, 0.05), '−0,25');
      expect(formatAxisValue(-0.0000001, 0.5), '0,0');
    });

    test('leitura do traço tira zeros à direita', () {
      expect(formatTraceValue(2.5), '2,5');
      expect(formatTraceValue(3), '3');
      expect(formatTraceValue(-1.23456), '−1,2346');
      expect(formatTraceValue(-0.00001), '0');
      expect(formatTraceValue(double.nan), 'indefinido');
    });
  });
}
