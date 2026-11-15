import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Parece um campo de busca, mas age como botão: a busca de verdade precisa
/// de uma tela própria (sugestões, histórico, resultados) e o teclado não
/// deve cobrir a Home.
class SearchEntry extends StatelessWidget {
  const SearchEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            // Altura mínima, e não fixa: com fonte ampliada a caixa cresce.
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.ciano),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Buscar conceitos, fórmulas ou matérias',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontText,
                      fontSize: 15,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
