import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/calculator_engine.dart';

/// Resposta da calculadora: o que foi calculado, o resultado em destaque e
/// o passo a passo ("Precisão a cada etapa").
///
/// A borda verde é a de "resultado validado" (Trabalho 1, seção 03); um
/// resultado numérico ganha o selo "Aproximação", para não se passar por
/// exato.
class CalculationResultCard extends StatelessWidget {
  const CalculationResultCard({super.key, required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final decimal = result.decimal;
    return Semantics(
      // O leitor de tela anuncia o resultado assim que ele aparece.
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: result.isApproximate
                ? AppColors.borda
                : AppColors.verdeConfirmacao,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap: com fonte ampliada, o selo desce para a linha de baixo.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('RESULTADO', style: AppTextStyles.rotulo),
                if (result.isApproximate) const _ApproximateBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              result.input,
              style: AppTextStyles.apoio.copyWith(
                fontFamily: AppTheme.fontMono,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              result.result,
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 22,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.brancoTecnico,
              ),
            ),
            if (decimal != null) ...[
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                '≈ $decimal',
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 15,
                  color: AppColors.ciano,
                ),
              ),
            ],
            if (result.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.borda, height: 1),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: const Text('PASSO A PASSO', style: AppTextStyles.rotulo),
              ),
              for (var i = 0; i < result.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}.',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.ciano,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          result.steps[i],
                          style: AppTextStyles.apoio.copyWith(
                            color: AppColors.brancoTecnico,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApproximateBadge extends StatelessWidget {
  const _ApproximateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.superficieElevada,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borda),
      ),
      // Ícone + texto: o aviso não depende só da cor.
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.blur_on_rounded,
            size: 14,
            color: AppColors.textoSecundario,
          ),
          SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Aproximação numérica',
              style: TextStyle(
                fontFamily: AppTheme.fontText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
