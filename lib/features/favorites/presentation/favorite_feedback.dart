import 'package:flutter/material.dart';

import '../../modules/domain/study_module.dart';
import 'favorites_controller.dart';

/// Alterna o favorito de [module] e confirma com uma SnackBar que permite
/// desfazer. Usado em todos os lugares com o botão de coração, para que a
/// resposta ao toque seja a mesma no app inteiro.
Future<void> toggleFavoriteWithFeedback(
  BuildContext context,
  FavoritesController favorites,
  StudyModule module,
) async {
  // Obtido antes do await: o contexto pode deixar de existir depois.
  final messenger = ScaffoldMessenger.of(context);

  void show(String text, {SnackBarAction? action}) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          // Desde o Flutter 3.35, uma SnackBar com ação fica na tela até ser
          // tocada (persist = action != null). Aqui a mensagem é só uma
          // confirmação com "Desfazer" opcional, então ela some sozinha.
          persist: false,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  try {
    final added = await favorites.toggle(module.id);
    show(
      added
          ? '${module.title} adicionado aos favoritos.'
          : '${module.title} removido dos favoritos.',
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () => favorites.toggle(module.id).ignore(),
      ),
    );
  } catch (_) {
    show('Não foi possível atualizar os favoritos. Tente novamente.');
  }
}
