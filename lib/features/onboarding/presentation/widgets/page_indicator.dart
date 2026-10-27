import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Indicador de progresso com uma barra por página; a ativa é ciano e mais larga.
class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6),
            width: i == current ? 28 : 12,
            height: 4,
            decoration: BoxDecoration(
              color: i == current ? AppColors.ciano : AppColors.borda,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
