import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Esqueleto da lista "Mais estudados": blocos no formato dos cartões, para
/// que a troca pelos dados não "pule" o layout.
class ModulesLoading extends StatelessWidget {
  const ModulesLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando módulos',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Container(
              height: 104,
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borda),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mensagem para os estados de erro e vazio (ícone + texto + ação opcional).
/// Quem decide o conteúdo é a página.
class ModulesMessage extends StatelessWidget {
  const ModulesMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.ciano),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.corpo.copyWith(fontSize: 14),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.ciano),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}
