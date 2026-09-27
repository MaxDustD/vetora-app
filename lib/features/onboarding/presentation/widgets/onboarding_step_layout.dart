import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'page_indicator.dart';

/// Layout comum às três páginas do onboarding (Trabalho 1, seção 07).
///
/// Ilustração na metade superior; indicador, rótulo e título sempre na mesma
/// altura, para que só a ilustração pareça mudar ao deslizar.
class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.index,
    required this.total,
    required this.title,
    required this.message,
    required this.illustration,
  });

  final int index;
  final int total;
  final String title;
  final String message;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    final number = (index + 1).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // Ilustração decorativa: não responde ao toque e é ignorada por leitores de tela.
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Center(child: FittedBox(child: illustration)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PageIndicator(count: total, current: index),
          const SizedBox(height: 20),
          Text(
            '$number / PRECISÃO A CADA ETAPA',
            style: AppTextStyles.rotulo.copyWith(color: AppColors.ciano),
          ),
          const SizedBox(height: 12),
          SizedBox(
            // Altura fixa para duas linhas: mantém a mensagem alinhada entre as páginas.
            height: 72,
            child: Text(title, style: AppTextStyles.titulo),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Text(message, style: AppTextStyles.corpo),
          ),
        ],
      ),
    );
  }
}

/// Grade técnica de baixo contraste, usada ao fundo das ilustrações.
class TechnicalGridPainter extends CustomPainter {
  const TechnicalGridPainter();

  static const step = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borda.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(TechnicalGridPainter oldDelegate) => false;
}

/// Etiqueta com uma fórmula em fonte mono, sobre superfície com borda de 1 px.
class FormulaTag extends StatelessWidget {
  const FormulaTag(this.formula, {super.key});

  final String formula;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borda),
      ),
      child: Text(
        formula,
        style: const TextStyle(
          fontFamily: AppTheme.fontMono,
          fontSize: 15,
          color: AppColors.brancoTecnico,
        ),
      ),
    );
  }
}
