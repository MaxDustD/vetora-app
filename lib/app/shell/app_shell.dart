import 'package:flutter/material.dart';

import '../../core/storage/profile_storage.dart';
import '../../features/calculator/presentation/calculator_page.dart';
import '../../features/favorites/data/favorites_storage.dart';
import '../../features/favorites/presentation/favorites_controller.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/favorites/presentation/widgets/favorite_button.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/modules/domain/study_module.dart';
import '../../features/modules/domain/study_module_repository.dart';
import '../../features/modules/presentation/pages/module_detail_page.dart';
import '../../features/modules/presentation/pages/module_search_page.dart';
import '../../features/profile/presentation/profile_page.dart';

/// Moldura fixa do app: a barra de navegação inferior e a aba ativa.
///
/// É também a raiz de composição das telas do catálogo; as dependências
/// chegam pelo construtor e são compartilhadas entre as telas.
///
/// O perfil e os favoritos ficam aqui porque várias telas os usam. Os
/// favoritos, ouvidos por três telas, já usam um [FavoritesController].
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    this.profileStorage = const ProfileStorage(),
    this.favoritesStorage = const FavoritesStorage(),
  });

  final StudyModuleRepository repository;
  final ProfileStorage profileStorage;
  final FavoritesStorage favoritesStorage;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeIndex = 0;
  static const _profileIndex = 3;

  int _selectedIndex = _homeIndex;
  UserProfile _profile = const UserProfile();
  late final FavoritesController _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = FavoritesController(storage: widget.favoritesStorage)..load();
    _loadProfile();
  }

  @override
  void dispose() {
    _favorites.dispose();
    super.dispose();
  }

  /// A tela do módulo é um fluxo que avança (e não uma aba): é empilhada
  /// sobre a shell, e o "voltar" retorna à aba de onde o usuário veio.
  void _openModule(StudyModule module) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModuleDetailPage(
          module: module,
          repository: widget.repository,
          trailingAction: FavoriteButton(module: module, favorites: _favorites),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModuleSearchPage(
          repository: widget.repository,
          favorites: _favorites,
          onOpenModule: _openModule,
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.profileStorage.load();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // Sem perfil salvo legível, a Home mostra o convite para completá-lo.
    }
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    // "Voltar" do Android: em outra aba, volta ao Início; só de lá sai do app.
    return PopScope(
      canPop: _selectedIndex == _homeIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(_homeIndex);
      },
      child: Scaffold(
        // IndexedStack mantém as abas vivas: ao voltar ao Início, a rolagem e
        // os dados carregados continuam onde estavam.
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(
              repository: widget.repository,
              profile: _profile,
              onOpenProfile: () => _select(_profileIndex),
              favorites: _favorites,
              onOpenModule: _openModule,
              onOpenSearch: _openSearch,
            ),
            // A aba não tem Scaffold próprio; a área segura vem daqui.
            const SafeArea(bottom: false, child: CalculatorPage()),
            FavoritesPage(
              repository: widget.repository,
              favorites: _favorites,
              onOpenModule: _openModule,
              onExplore: () => _select(_homeIndex),
            ),
            ProfilePage(
              profile: _profile,
              storage: widget.profileStorage,
              onSaved: (profile) => setState(() => _profile = profile),
            ),
          ],
        ),
        // Ícone + rótulo sempre; contornado quando inativo, preenchido quando
        // ativo: o estado não depende só da cor.
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate_rounded),
              label: 'Calculadora',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
