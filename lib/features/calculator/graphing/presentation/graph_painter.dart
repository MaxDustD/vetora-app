import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/curve_sampler.dart';
import '../domain/graph_viewport.dart';

/// Uma curva pronta para desenhar: a função e a sua cor.
class PlottedCurve {
  const PlottedCurve({required this.function, required this.color});

  final double Function(double x) function;
  final Color color;
}

/// Desenha grade, eixos, números dos eixos, curvas e o ponto de leitura.
///
/// Não guarda estado: recebe a janela e as curvas a cada quadro. Toda a
/// matemática fica em [GraphViewport] e [sampleCurve].
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.viewport,
    required this.curves,
    this.traceX,
    this.textScaler = TextScaler.noScaling,
  });

  final GraphViewport viewport;
  final List<PlottedCurve> curves;

  /// Abscissa do traço (linha vertical de leitura); `null` sem traço.
  final double? traceX;

  /// Escala de texto do sistema, para os números dos eixos acompanharem a
  /// fonte ampliada.
  final TextScaler textScaler;

  static const _gridMinor = Color(0xFF181D20);
  static const _gridMajor = AppColors.borda;
  static const _axis = AppColors.textoTerciario;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.superficie);

    final step = niceTickStep(viewport.width, targetTicks: 6);
    final stepY = niceTickStep(viewport.height, targetTicks: 6);

    _paintGrid(canvas, size, step, stepY);
    _paintAxes(canvas, size);
    _paintLabels(canvas, size, step, stepY);
    for (final curve in curves) {
      _paintCurve(canvas, size, curve);
    }
    _paintTrace(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size, double step, double stepY) {
    final minor = Paint()
      ..color = _gridMinor
      ..strokeWidth = 1;
    final major = Paint()
      ..color = _gridMajor
      ..strokeWidth = 1;

    // Linhas secundárias a cada quinto do passo principal.
    for (final (lineStep, paint) in [(step / 5, minor), (step, major)]) {
      final start = (viewport.xMin / lineStep).ceil();
      final end = (viewport.xMax / lineStep).floor();
      for (var i = start; i <= end; i++) {
        final px = viewport.toScreenX(i * lineStep, size.width);
        canvas.drawLine(Offset(px, 0), Offset(px, size.height), paint);
      }
    }
    for (final (lineStep, paint) in [(stepY / 5, minor), (stepY, major)]) {
      final start = (viewport.yMin / lineStep).ceil();
      final end = (viewport.yMax / lineStep).floor();
      for (var i = start; i <= end; i++) {
        final py = viewport.toScreenY(i * lineStep, size.height);
        canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
      }
    }
  }

  void _paintAxes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _axis
      ..strokeWidth = 1.5;
    if (viewport.yMin <= 0 && viewport.yMax >= 0) {
      final py = viewport.toScreenY(0, size.height);
      canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
    }
    if (viewport.xMin <= 0 && viewport.xMax >= 0) {
      final px = viewport.toScreenX(0, size.width);
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), paint);
    }
  }

  /// Números junto aos eixos. Se um eixo está fora da tela, os números
  /// ficam presos à borda mais próxima, para nunca sumirem.
  void _paintLabels(Canvas canvas, Size size, double step, double stepY) {
    const margin = 4.0;
    final axisY = viewport.toScreenY(0, size.height);
    final axisX = viewport.toScreenX(0, size.width);

    final start = (viewport.xMin / step).ceil();
    final end = (viewport.xMax / step).floor();
    for (var i = start; i <= end; i++) {
      if (i == 0) continue;
      final value = i * step;
      final label = _layoutLabel(formatAxisValue(value, step));
      final px = viewport.toScreenX(value, size.width) - label.width / 2;
      // max(): num gráfico mais baixo que o rótulo, o limite superior
      // ficaria abaixo do inferior e o clamp falharia.
      final py = (axisY + margin)
          .clamp(margin, math.max(margin, size.height - label.height - margin))
          .toDouble();
      label.paint(canvas, Offset(px, py));
    }

    final startY = (viewport.yMin / stepY).ceil();
    final endY = (viewport.yMax / stepY).floor();
    for (var i = startY; i <= endY; i++) {
      if (i == 0) continue;
      final value = i * stepY;
      final label = _layoutLabel(formatAxisValue(value, stepY));
      final py = viewport.toScreenY(value, size.height) - label.height / 2;
      final px = (axisX + margin)
          .clamp(margin, math.max(margin, size.width - label.width - margin))
          .toDouble();
      label.paint(canvas, Offset(px, py));
    }
  }

  TextPainter _layoutLabel(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: AppTheme.fontMono,
          fontSize: 10,
          color: AppColors.textoSecundario,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
  }

  void _paintCurve(Canvas canvas, Size size, PlottedCurve curve) {
    final paint = Paint()
      ..color = curve.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final segments = sampleCurve(
      curve.function,
      viewport,
      samples: size.width.ceil() + 1,
    );
    for (final segment in segments) {
      final points = [
        for (final p in segment)
          Offset(
            viewport.toScreenX(p.x, size.width),
            // Limita o y desenhado: valores enormes viram coordenadas que
            // alguns backends gráficos não desenham corretamente.
            viewport
                .toScreenY(p.y, size.height)
                .clamp(-size.height * 4, size.height * 5),
          ),
      ];
      canvas.drawPoints(ui.PointMode.polygon, points, paint);
    }
  }

  void _paintTrace(Canvas canvas, Size size) {
    final x = traceX;
    if (x == null) return;
    final px = viewport.toScreenX(x, size.width);
    canvas.drawLine(
      Offset(px, 0),
      Offset(px, size.height),
      Paint()
        ..color = AppColors.textoSecundario
        ..strokeWidth = 1,
    );
    for (final curve in curves) {
      double y;
      try {
        y = curve.function(x);
      } catch (_) {
        continue;
      }
      if (!y.isFinite) continue;
      final center = Offset(px, viewport.toScreenY(y, size.height));
      canvas
        ..drawCircle(center, 6, Paint()..color = AppColors.superficie)
        ..drawCircle(
          center,
          6,
          Paint()
            ..color = curve.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) =>
      oldDelegate.viewport != viewport ||
      oldDelegate.curves != curves ||
      oldDelegate.traceX != traceX ||
      oldDelegate.textScaler != textScaler;
}
