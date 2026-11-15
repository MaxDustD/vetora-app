import 'graph_viewport.dart';

/// Ponto do plano. Pura Dart, para a amostragem ser testável sem Flutter.
class GraphPoint {
  const GraphPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is GraphPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'GraphPoint($x, $y)';
}

/// Amostra `f` na janela e devolve trechos contínuos da curva.
///
/// A curva é quebrada em trechos quando:
/// - `f` não está definida (NaN ou infinito: raiz de negativo, ln de zero…);
/// - dois pontos vizinhos saltam mais que [jumpFactor] alturas da janela,
///   sinal de assíntota (1/x, tg x). Sem isso, o desenho ligaria +∞ a −∞
///   com uma reta vertical falsa.
///
/// [samples] costuma ser a largura em pixels: um ponto por pixel.
List<List<GraphPoint>> sampleCurve(
  double Function(double x) f,
  GraphViewport viewport, {
  required int samples,
  double jumpFactor = 1.5,
}) {
  final segments = <List<GraphPoint>>[];
  var current = <GraphPoint>[];
  final maxJump = viewport.height * jumpFactor;
  final count = samples < 2 ? 2 : samples;

  void closeSegment() {
    if (current.length > 1) segments.add(current);
    current = <GraphPoint>[];
  }

  for (var i = 0; i < count; i++) {
    final x = viewport.xMin + viewport.width * i / (count - 1);
    double y;
    try {
      y = f(x);
    } catch (_) {
      y = double.nan;
    }

    if (!y.isFinite) {
      closeSegment();
      continue;
    }
    if (current.isNotEmpty && (y - current.last.y).abs() > maxJump) {
      closeSegment();
    }
    current.add(GraphPoint(x, y));
  }
  closeSegment();
  return segments;
}
