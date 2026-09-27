import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/area_chip.dart';
import 'onboarding_step_layout.dart';

/// Página 1 — diagrama de um corpo sobre grade técnica, com vetor resultante
/// (ciano), peso (cinza), trajetória tracejada e duas etiquetas de fórmula.
class BodyDiagramIllustration extends StatelessWidget {
  const BodyDiagramIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: const Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: TechnicalGridPainter()),
            ),
            Positioned.fill(child: CustomPaint(painter: _BodyDiagramPainter())),
            Positioned(left: 16, top: 20, child: FormulaTag('F = m · a')),
            Positioned(right: 16, bottom: 20, child: FormulaTag('v = Δs / Δt')),
          ],
        ),
      ),
    );
  }
}

class _BodyDiagramPainter extends CustomPainter {
  const _BodyDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Offset(size.width * 0.5, size.height * 0.5);
    const radius = 24.0;

    // Trajetória tracejada até o corpo
    final trajectory = Path()
      ..moveTo(20, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.3,
        body.dx,
        body.dy,
      );
    _drawDashed(
      canvas,
      trajectory,
      Paint()
        ..color = AppColors.textoTerciario
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Peso (vetor cinza vertical)
    _drawArrow(
      canvas,
      from: body.translate(0, radius),
      to: body.translate(0, 90),
      color: AppColors.cinzaEngrenagem,
    );
    // Resultante (vetor ciano)
    final direction = Offset(math.cos(-0.6), math.sin(-0.6));
    _drawArrow(
      canvas,
      from: body + direction * radius,
      to: body + direction * 120,
      color: AppColors.ciano,
    );

    // Corpo
    canvas.drawCircle(
      body,
      radius,
      Paint()..color = AppColors.superficieElevada,
    );
    canvas.drawCircle(
      body,
      radius,
      Paint()
        ..color = AppColors.brancoTecnico
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawLabel(
      canvas,
      'F',
      body + direction * 120 + const Offset(6, -2),
      AppColors.ciano,
    );
    _drawLabel(canvas, 'P', body.translate(10, 72), AppColors.cinzaEngrenagem);
  }

  void _drawArrow(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    final angle = (to - from).direction;
    const head = 12.0;
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - head * math.cos(angle - 0.45),
        to.dy - head * math.sin(angle - 0.45),
      )
      ..lineTo(
        to.dx - head * math.cos(angle + 0.45),
        to.dy - head * math.sin(angle + 0.45),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTheme.fontMono,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_BodyDiagramPainter oldDelegate) => false;
}

/// Página 2 — exercício de movimento resolvido: dados → resultado → fórmula e
/// conversão. 120 m ÷ 8 s = 15 m/s = 54 km/h.
class SolvedExerciseIllustration extends StatelessWidget {
  const SolvedExerciseIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DADOS · MOVIMENTO', style: AppTextStyles.rotulo),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _Quantity(symbol: 'd', value: '120', unit: 'm'),
                    ),
                    Expanded(
                      child: _Quantity(symbol: 't', value: '8', unit: 's'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'velocidade média?',
                  style: AppTextStyles.corpo.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          // Conector de etapas
          Container(width: 2, height: 20, color: AppColors.ciano),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.ciano,
            size: 20,
          ),
          _Panel(
            borderColor: AppColors.verdeConfirmacao,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESULTADO', style: AppTextStyles.rotulo),
                      SizedBox(height: 6),
                      _Value(value: '15', unit: 'm/s', fontSize: 32),
                    ],
                  ),
                ),
                const _ConfirmationSeal(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _DetailLine(label: 'FÓRMULA', value: 'v = d ÷ t'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DetailLine(label: 'CONVERSÃO', value: '54 km/h'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Página 3 — prévia da interface de cálculo: chip de área, visor com
/// F = 12 × 9,81 = 117,72 N e parte do teclado.
class CalculatorPreviewIllustration extends StatelessWidget {
  const CalculatorPreviewIllustration({super.key});

  static const _keys = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '+'],
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AreaChip('Mecânica'),
          const SizedBox(height: 12),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FORÇA RESULTANTE', style: AppTextStyles.rotulo),
                const SizedBox(height: 10),
                Text(
                  'F = 12 × 9,81',
                  style: AppTextStyles.corpo.copyWith(
                    fontFamily: AppTheme.fontMono,
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _Value(value: '117,72', unit: 'N', fontSize: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final row in _keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _Key(key, isOperation: row.last == key),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.borderColor = AppColors.borda});

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

/// Número em fonte mono com a unidade em ciano.
class _Value extends StatelessWidget {
  const _Value({required this.value, required this.unit, this.fontSize = 18});

  final String value;
  final String unit;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: value,
        style: AppTextStyles.valor.copyWith(fontSize: fontSize),
        children: [
          TextSpan(
            text: ' $unit',
            style: TextStyle(fontSize: fontSize * 0.7, color: AppColors.ciano),
          ),
        ],
      ),
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity({
    required this.symbol,
    required this.value,
    required this.unit,
  });

  final String symbol;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$symbol = ',
          style: AppTextStyles.valor.copyWith(
            fontSize: 18,
            color: AppColors.textoSecundario,
          ),
        ),
        _Value(value: value, unit: unit, fontSize: 20),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.rotulo.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.valor.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class _ConfirmationSeal extends StatelessWidget {
  const _ConfirmationSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.cianoProfundo,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: AppColors.ciano, size: 22),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.label, {this.isOperation = false});

  final String label;
  final bool isOperation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isOperation
            ? AppColors.cianoProfundo
            : AppColors.superficieElevada,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontMono,
          fontSize: 18,
          color: isOperation ? AppColors.ciano : AppColors.brancoTecnico,
        ),
      ),
    );
  }
}
