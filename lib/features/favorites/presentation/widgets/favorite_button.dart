import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../modules/domain/study_module.dart';
import '../favorite_feedback.dart';
import '../favorites_controller.dart';

/// Coração de favoritar. Ouve o [FavoritesController] sozinho, então pode
/// ser colocado em qualquer tela (cartão, barra da tela do módulo) sem que
/// ela precise conhecer os favoritos.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.module,
    required this.favorites,
  });

  final StudyModule module;
  final FavoritesController favorites;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
        final isFavorite = favorites.isFavorite(module.id);
        // Contornado × preenchido: o estado não depende só da cor.
        return IconButton(
          tooltip: isFavorite
              ? 'Remover ${module.title} dos favoritos'
              : 'Adicionar ${module.title} aos favoritos',
          isSelected: isFavorite,
          color: AppColors.ciano,
          selectedIcon: const Icon(Icons.favorite_rounded),
          icon: const Icon(Icons.favorite_border_rounded),
          onPressed: () =>
              toggleFavoriteWithFeedback(context, favorites, module),
        );
      },
    );
  }
}
