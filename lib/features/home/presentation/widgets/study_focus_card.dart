import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Resumo das preferências de quem já completou o perfil. Ocupa o lugar do
/// [ProfilePromptCard] depois que o convite foi aceito.
class StudyFocusCard extends StatelessWidget {
  const StudyFocusCard({
    super.key,
    required this.preferences,
    required this.onEdit,
  });

  final List<String> preferences;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.track_changes_rounded, color: AppColors.ciano),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Seu foco de estudo',
                    style: AppTextStyles.tituloCartao,
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(foregroundColor: AppColors.ciano),
                  child: const Text('EDITAR'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: preferences.isEmpty
                  ? const Text(
                      'Escolha temas no seu perfil e veja primeiro os módulos '
                      'da sua área.',
                      style: AppTextStyles.apoio,
                    )
                  : Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final preference in preferences)
                          Chip(
                            avatar: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: AppColors.ciano,
                            ),
                            label: Text(preference),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
