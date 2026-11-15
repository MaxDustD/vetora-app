import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Título de seção com ação opcional ("Ver todos").
///
/// Marcado como cabeçalho: o leitor de tela permite pular de título em título.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Cópias locais permitem a promoção de tipo (String? → String).
    final label = actionLabel;
    final sub = subtitle;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.secao),
              ),
              if (sub != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(sub, style: AppTextStyles.apoio),
              ],
            ],
          ),
        ),
        if (label != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.ciano),
            child: Text(label),
          ),
      ],
    );
  }
}
