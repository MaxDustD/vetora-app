import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../modules/domain/engineering_area.dart';
import '../../../modules/presentation/engineering_area_icon.dart';

/// Atalhos por área (promessa "Conecte a teoria à prática").
///
/// Um atalho por valor de [EngineeringArea], na ordem do enum: uma área nova
/// aparece aqui sem mexer na Home. Tocar filtra a lista; tocar de novo na
/// área selecionada desfaz o filtro.
class AreaShortcuts extends StatelessWidget {
  const AreaShortcuts({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EngineeringArea? selected;
  final ValueChanged<EngineeringArea> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final area in EngineeringArea.values)
          Expanded(
            child: _AreaTile(
              area: area,
              isSelected: area == selected,
              onTap: () => onSelected(area),
            ),
          ),
      ],
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  final EngineeringArea area;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: area.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.cianoProfundo
                      : AppColors.superficie,
                  shape: BoxShape.circle,
                  // O estado selecionado não depende só da cor: a borda
                  // também muda de espessura.
                  border: Border.all(
                    color: isSelected ? AppColors.ciano : AppColors.borda,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(area.icon, color: AppColors.ciano),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                area.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontText,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.brancoTecnico
                      : AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
