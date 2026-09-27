import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Chip de área de cálculo (ex.: "Mecânica").
class AreaChip extends StatelessWidget {
  const AreaChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.superficieElevada,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borda),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.fontMono,
          fontSize: 13,
          color: AppColors.ciano,
        ),
      ),
    );
  }
}
