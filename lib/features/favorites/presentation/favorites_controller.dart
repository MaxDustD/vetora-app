import 'package:flutter/foundation.dart';

import '../data/favorites_storage.dart';

/// Estado dos favoritos, compartilhado pela Home, pela aba Favoritos e pela
/// tela do módulo.
///
/// É o primeiro dado usado por várias telas ao mesmo tempo, e por isso sai do
/// `setState` de uma tela só: um [ChangeNotifier] criado na [AppShell] (raiz
/// de composição) e ouvido com `ListenableBuilder` por quem precisa.
class FavoritesController extends ChangeNotifier {
  FavoritesController({this.storage = const FavoritesStorage()});

  final FavoritesStorage storage;

  List<String> _ids = const [];
  bool _isLoaded = false;
  bool _isDisposed = false;

  /// Ids favoritos, do mais recente para o mais antigo.
  List<String> get ids => _ids;

  /// `false` até a primeira leitura do armazenamento terminar.
  bool get isLoaded => _isLoaded;

  bool isFavorite(String moduleId) => _ids.contains(moduleId);

  Future<void> load() async {
    try {
      _ids = List.unmodifiable(await storage.load());
    } catch (_) {
      // Sem favoritos legíveis, começa vazio: o app continua utilizável.
      _ids = const [];
    }
    _isLoaded = true;
    _notify();
  }

  /// Adiciona ou remove [moduleId] e devolve `true` se ele passou a ser
  /// favorito.
  ///
  /// A tela muda na hora (atualização otimista). Se a gravação falhar, o
  /// estado anterior volta e o erro é relançado, para a tela avisar o usuário.
  Future<bool> toggle(String moduleId) async {
    final previous = _ids;
    final adding = !previous.contains(moduleId);
    _ids = List.unmodifiable(
      adding
          ? [moduleId, ...previous]
          : [
              for (final id in previous)
                if (id != moduleId) id,
            ],
    );
    _notify();

    try {
      await storage.save(_ids);
    } catch (_) {
      _ids = previous;
      _notify();
      rethrow;
    }
    return adding;
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
