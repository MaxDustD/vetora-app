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
  const StudyModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.trailing,
  });

  final StudyModule module;
  final VoidCallback onTap;

  /// Ação própria do cartão (ex.: o botão de favoritar). Sem ela, uma seta
  /// indica que o cartão abre o módulo.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final details = [
      module.area.label,
      formatCount(module.topicCount, 'tópico', 'tópicos'),
      formatDuration(module.durationInMinutes),
    ].join(' · ');
    final action = trailing;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // MergeSemantics por fora do InkWell: textos e toque viram um só
            // item para o leitor de tela. A ação extra fica de fora, como um
            // segundo item: dois botões em um nó só seriam inacessíveis.
            child: MergeSemantics(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    action == null ? AppSpacing.sm : 0,
                    AppSpacing.md,
                  ),
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
                            if (module.subtitle.isNotEmpty)
                              Text(
                                module.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.apoio.copyWith(
                                  color: AppColors.ciano,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(details, style: AppTextStyles.apoio),
                            const SizedBox(height: AppSpacing.sm),
                            // Wrap: se os selos não couberem lado a lado,
                            // descem de linha.
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
                      if (action == null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textoTerciario,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: action,
            ),
        ],
      ),
    );
  }
}
