import 'dart:math' as math;

/// A janela do plano cartesiano que o gráfico mostra.
///
/// Imutável e sem Flutter: arrastar e dar zoom produzem uma janela nova, e
/// a matemática (conversões, marcas dos eixos) é testável sem tela.
class GraphViewport {
  const GraphViewport({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  }) : assert(xMax > xMin),
       assert(yMax > yMin);

  /// Janela inicial: −10 a 10 em x e −6 a 6 em y.
  static const initial = GraphViewport(xMin: -10, xMax: 10, yMin: -6, yMax: 6);

  /// Limites do zoom: abaixo disso a precisão de `double` aparece no
  /// desenho; acima, os números dos eixos ficam ilegíveis.
  static const double minSpan = 1e-4;
  static const double maxSpan = 1e6;

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  double get width => xMax - xMin;
  double get height => yMax - yMin;

  /// Desloca a janela em unidades do plano (não em pixels).
  GraphViewport panBy(double dx, double dy) => GraphViewport(
    xMin: xMin + dx,
    xMax: xMax + dx,
    yMin: yMin + dy,
    yMax: yMax + dy,
  );

  /// Aproxima ([factor] > 1) ou afasta ([factor] < 1) mantendo o ponto
  /// ([focusX], [focusY]) parado na tela, como no gesto de pinça.
  GraphViewport zoom(double factor, {double? focusX, double? focusY}) {
    final fx = focusX ?? (xMin + xMax) / 2;
    final fy = focusY ?? (yMin + yMax) / 2;
    final newWidth = (width / factor).clamp(minSpan, maxSpan);
    final newHeight = (height / factor).clamp(minSpan, maxSpan);
    // Fração do ponto focal dentro da janela: igual antes e depois.
    final tx = (fx - xMin) / width;
    final ty = (fy - yMin) / height;
    return GraphViewport(
      xMin: fx - tx * newWidth,
      xMax: fx + (1 - tx) * newWidth,
      yMin: fy - ty * newHeight,
      yMax: fy + (1 - ty) * newHeight,
    );
  }

  /// Ajusta a altura para que uma unidade em x e em y tenham o mesmo
  /// tamanho na tela (círculos parecem círculos), mantendo o centro.
  GraphViewport withAspectRatio(double pixelWidth, double pixelHeight) {
    if (pixelWidth <= 0 || pixelHeight <= 0) return this;
    final centerY = (yMin + yMax) / 2;
    final newHeight = width * pixelHeight / pixelWidth;
    return GraphViewport(
      xMin: xMin,
      xMax: xMax,
      yMin: centerY - newHeight / 2,
      yMax: centerY + newHeight / 2,
    );
  }

  // Conversões entre o plano e a tela (y da tela cresce para baixo).

  double toScreenX(double x, double pixelWidth) =>
      (x - xMin) / width * pixelWidth;

  double toScreenY(double y, double pixelHeight) =>
      (yMax - y) / height * pixelHeight;

  double toWorldX(double px, double pixelWidth) =>
      xMin + px / pixelWidth * width;

  double toWorldY(double py, double pixelHeight) =>
      yMax - py / pixelHeight * height;

  @override
  bool operator ==(Object other) =>
      other is GraphViewport &&
      other.xMin == xMin &&
      other.xMax == xMax &&
      other.yMin == yMin &&
      other.yMax == yMax;

  @override
  int get hashCode => Object.hash(xMin, xMax, yMin, yMax);
}

/// Passo "redondo" entre as marcas de um eixo (1, 2 ou 5 × 10ⁿ) para que
/// [span] tenha cerca de [targetTicks] marcas.
double niceTickStep(double span, {int targetTicks = 8}) {
  final raw = span / targetTicks;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final normalized = raw / magnitude;
  final nice = normalized < 1.5
      ? 1
      : normalized < 3
      ? 2
      : normalized < 7
      ? 5
      : 10;
  return nice * magnitude;
}

/// Número de um eixo em pt-BR, com as casas decimais que o [step] exige
/// (passo 0,5 → "1,5"; passo 2 → "4").
String formatAxisValue(double value, double step) {
  final decimals = math.max(0, -(math.log(step) / math.ln10).floor());
  // Evita "-0" quando o valor arredonda para zero.
  final rounded = double.parse(value.toStringAsFixed(decimals));
  final text = (rounded == 0 ? 0.0 : rounded).toStringAsFixed(decimals);
  return text.replaceAll('.', ',').replaceAll('-', '−');
}

/// Valor de leitura do traço: até 4 casas, sem zeros à direita ("2,5").
String formatTraceValue(double value) {
  if (value.isNaN || value.isInfinite) return 'indefinido';
  var text = value.toStringAsFixed(4);
  if (text.contains('.')) {
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  if (text == '-0') text = '0';
  return text.replaceAll('.', ',').replaceAll('-', '−');
}
