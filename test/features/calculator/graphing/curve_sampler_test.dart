import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/calculator/graphing/domain/curve_sampler.dart';
import 'package:vetora/features/calculator/graphing/domain/graph_viewport.dart';

void main() {
  const viewport = GraphViewport(xMin: -10, xMax: 10, yMin: -6, yMax: 6);

  test('função contínua vira um único trecho, de borda a borda', () {
    final segments = sampleCurve((x) => 2 * x + 1, viewport, samples: 101);
    expect(segments, hasLength(1));
    expect(segments.single.first, const GraphPoint(-10, -19));
    expect(segments.single.last, const GraphPoint(10, 21));
    expect(segments.single, hasLength(101));
  });

  test('assíntota de 1/x quebra a curva em dois trechos', () {
    final segments = sampleCurve((x) => 1 / x, viewport, samples: 200);
    expect(segments, hasLength(2));
    expect(segments.first.every((p) => p.x < 0), isTrue);
    expect(segments.last.every((p) => p.x > 0), isTrue);
  });

  test('tangente é quebrada em cada assíntota visível', () {
    // Em [−10, 10] há 6 assíntotas de tg x (±π/2, ±3π/2, ±5π/2).
    final segments = sampleCurve(math.tan, viewport, samples: 2000);
    expect(segments, hasLength(7));
  });

  test('pontos fora do domínio são ignorados (raiz de negativo)', () {
    final segments = sampleCurve(
      (x) => x < 0 ? double.nan : math.sqrt(x),
      viewport,
      samples: 101,
    );
    expect(segments, hasLength(1));
    expect(segments.single.every((p) => p.x >= 0), isTrue);
  });

  test('uma função que lança erro não derruba o gráfico', () {
    final segments = sampleCurve(
      (x) => x > 0 ? throw StateError('falha') : x,
      viewport,
      samples: 101,
    );
    expect(segments, hasLength(1));
    expect(segments.single.every((p) => p.x <= 0), isTrue);
  });

  test('função sem pontos definidos não gera trechos', () {
    expect(sampleCurve((_) => double.nan, viewport, samples: 50), isEmpty);
  });
}
