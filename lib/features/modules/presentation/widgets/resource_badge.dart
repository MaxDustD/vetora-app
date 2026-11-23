import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/module_resource.dart';

/// Selo de recurso do módulo ("✓ Exercícios resolvidos").
///
/// Ícone + texto: a informação não depende só da cor.
class ResourceBadge extends StatelessWidget {
  const ResourceBadge({super.key, required this.resource});

  final ModuleResource resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.cianoProfundo,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.ciano),
          const SizedBox(width: AppSpacing.xs),
          // Flexible + ellipsis: com fonte ampliada, o texto encolhe em vez
          // de transbordar.
          Flexible(
            child: Text(
              resource.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brancoTecnico,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
