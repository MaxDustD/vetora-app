import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Convite para completar o perfil (promessa "Estude no seu ritmo").
///
/// Um destaque, uma ação. Some quando o perfil já foi preenchido: um convite
/// que continua depois de aceito vira ruído.
class ProfilePromptCard extends StatelessWidget {
  const ProfilePromptCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cianoProfundo,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.ciano),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Complete seu perfil de estudos',
                  style: AppTextStyles.tituloCartao,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Microcopy orientada a benefício: o que fazer e o que se ganha.
          Text(
            'Conte o que você estuda e veja primeiro os módulos da sua área.',
            style: AppTextStyles.apoio.copyWith(
              color: AppColors.brancoTecnico.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              // Largura do texto, alinhado à esquerda; 48 dp de toque.
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text('Completar perfil'),
          ),
        ],
      ),
    );
  }
}
