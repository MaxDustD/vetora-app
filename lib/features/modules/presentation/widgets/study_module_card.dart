import 'package:flutter/material.dart';

import '../../../../core/common/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/study_module.dart';
import '../engineering_area_icon.dart';
import 'resource_badge.dart';

/// Cartão de um módulo de estudo.
///
/// Hierarquia: 1. título (o que é) → 2. contexto (área, tópicos, duração) →
/// 3. recursos (o que vou encontrar).
class StudyModuleCard extends StatelessWidget {
  const StudyModuleCard({super.key, required this.module, required this.onTap});

  final StudyModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      module.area.label,
      formatCount(module.topicCount, 'tópico', 'tópicos'),
      formatDuration(module.durationInMinutes),
    ].join(' · ');

    // MergeSemantics por fora do InkWell: textos e ação de toque viram um
    // único item para o leitor de tela.
    return MergeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.superficieElevada,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(module.area.icon, color: AppColors.ciano),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.tituloCartao,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(details, style: AppTextStyles.apoio),
                      const SizedBox(height: AppSpacing.sm),
                      // Wrap: se os selos não couberem lado a lado, descem.
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final resource in module.resources)
                            ResourceBadge(resource: resource),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textoTerciario,
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
