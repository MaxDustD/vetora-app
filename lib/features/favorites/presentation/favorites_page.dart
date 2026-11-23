import 'package:flutter/material.dart';

import '../../../core/common/formatters.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_views.dart';
import '../../modules/domain/study_module.dart';
import '../../modules/domain/study_module_repository.dart';
import '../../modules/presentation/widgets/study_module_card.dart';
import 'favorites_controller.dart';
import 'widgets/favorite_button.dart';

/// Aba "Favoritos": os módulos que o usuário guardou, do mais recente para o
/// mais antigo (promessa "retome seus temas favoritos" do onboarding).
///
/// O catálogo vem do repositório; quais módulos aparecem vem do
/// [FavoritesController]. Assim, favoritar na Home atualiza esta aba na hora,
/// sem nova busca.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.onOpenModule,
    required this.onExplore,
  });

  final StudyModuleRepository repository;
  final FavoritesController favorites;
  final ValueChanged<StudyModule> onOpenModule;

  /// Leva à aba Início, de onde se favoritam módulos.
  final VoidCallback onExplore;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<StudyModule>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = widget.repository.fetchAll();
  }

  void _reload() {
    setState(() {
      _catalogFuture = widget.repository.fetchAll();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _catalogFuture;
    } catch (_) {
      // O erro já é exibido pelo FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(
            pinned: true,
            titleSpacing: AppSpacing.lg,
            title: Text('Favoritos', style: AppTextStyles.secao),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.sm,
              horizontalPadding,
              AppSpacing.xl,
            ),
            sliver: FutureBuilder<List<StudyModule>>(
              future: _catalogFuture,
              builder: (context, snapshot) => ListenableBuilder(
                listenable: widget.favorites,
                builder: (context, _) => _buildContent(snapshot),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncSnapshot<List<StudyModule>> snapshot) {
    final isLoading =
        (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) ||
        !widget.favorites.isLoaded;
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: SkeletonList(semanticLabel: 'Carregando favoritos'),
      );
    }

    if (snapshot.hasError) {
      return SliverToBoxAdapter(
        child: StatusMessage(
          icon: Icons.cloud_off_outlined,
          message: 'Não foi possível carregar seus favoritos.',
          actionLabel: 'Tentar novamente',
          onAction: _reload,
        ),
      );
    }

    // Na ordem dos favoritos; ids que sumiram do catálogo são ignorados.
    final catalog = {
      for (final module in snapshot.data ?? const <StudyModule>[])
        module.id: module,
    };
    final modules = [for (final id in widget.favorites.ids) ?catalog[id]];

    if (modules.isEmpty) {
      return SliverToBoxAdapter(
        child: StatusMessage(
          icon: Icons.favorite_border_rounded,
          message:
              'Você ainda não tem favoritos. Toque no coração de um módulo '
              'para guardá-lo aqui.',
          actionLabel: 'Explorar módulos',
          onAction: widget.onExplore,
        ),
      );
    }

    return SliverList.separated(
      itemCount: modules.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            formatCount(
              modules.length,
              'módulo guardado',
              'módulos guardados',
            ).toUpperCase(),
            style: AppTextStyles.rotulo,
          );
        }
        final module = modules[index - 1];
        return StudyModuleCard(
          module: module,
          onTap: () => widget.onOpenModule(module),
          trailing: FavoriteButton(module: module, favorites: widget.favorites),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    );
  }
}
