import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_views.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/engineering_area.dart';
import '../../domain/module_search.dart';
import '../../domain/study_module.dart';
import '../../domain/study_module_repository.dart';
import '../module_search_controller.dart';
import '../widgets/study_module_card.dart';

class ModuleSearchPage extends StatefulWidget {
  const ModuleSearchPage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.onOpenModule,
  });

  final StudyModuleRepository repository;
  final FavoritesController favorites;
  final ValueChanged<StudyModule> onOpenModule;

  @override
  State<ModuleSearchPage> createState() => _ModuleSearchPageState();
}

class _ModuleSearchPageState extends State<ModuleSearchPage> {
  static const _debounceDuration = Duration(milliseconds: 300);

  late final ModuleSearchController _controller;
  late final TextEditingController _textController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = ModuleSearchController(repository: widget.repository);
    _textController = TextEditingController();
    _controller.load();
  }

  @override
  void didUpdateWidget(covariant ModuleSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = _controller.filters.query;
    if (query != _textController.text) {
      _timer?.cancel();
      _textController.text = query;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _timer?.cancel();
    _timer = Timer(_debounceDuration, () {
      _controller.updateFilters(_controller.filters.copyWith(query: query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppLayout.horizontalPadding(width);

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, widget.favorites]),
      builder: (context, _) {
        final filters = _controller.filters;
        if (filters.query != _textController.text) {
          _timer?.cancel();
          _textController.text = filters.query;
        }

        final results = applyModuleSearch(
          _controller.catalog,
          filters,
          favoriteIds: widget.favorites.ids.toSet(),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Buscar módulos')),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppSpacing.sm,
                  padding,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    TextField(
                      controller: _textController,
                      onChanged: _onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Buscar conceitos, fórmulas ou matérias',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilterChip(
                          label: const Text('Só favoritos'),
                          selected: filters.onlyFavorites,
                          onSelected: (selected) => _controller.updateFilters(
                            filters.copyWith(onlyFavorites: selected),
                          ),
                        ),
                        for (final area in EngineeringArea.values)
                          FilterChip(
                            label: Text(area.shortLabel),
                            selected: filters.areas.contains(area),
                            onSelected: (_) => _controller.toggleArea(area),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      children: [
                        if (_controller.status == ModuleSearchStatus.ready)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '${results.length} ${results.length == 1 ? 'módulo encontrado' : 'módulos encontrados'}',
                              style: AppTextStyles.apoio,
                            ),
                          ),
                        DropdownButton<ModuleSearchSort>(
                          value: filters.sort,
                          onChanged: (sort) {
                            if (sort != null) {
                              _controller.updateFilters(
                                filters.copyWith(sort: sort),
                              );
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ModuleSearchSort.title,
                              child: Text('A–Z'),
                            ),
                            DropdownMenuItem(
                              value: ModuleSearchSort.duration,
                              child: Text('Menor duração'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (filters.activeCount > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _controller.clearFilters,
                          child: const Text('Limpar filtros'),
                        ),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppSpacing.md,
                  padding,
                  AppSpacing.xl,
                ),
                sliver: _buildResults(results),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(List<StudyModule> results) {
    switch (_controller.status) {
      case ModuleSearchStatus.loading:
        return const SliverToBoxAdapter(
          child: SkeletonList(semanticLabel: 'Carregando módulos'),
        );
      case ModuleSearchStatus.failure:
        return SliverToBoxAdapter(
          child: StatusMessage(
            icon: Icons.cloud_off_outlined,
            message: 'Não foi possível carregar os módulos.',
            actionLabel: 'Tentar novamente',
            onAction: _controller.load,
          ),
        );
      case ModuleSearchStatus.ready:
        if (results.isEmpty) {
          return SliverToBoxAdapter(
            child: StatusMessage(
              icon: Icons.search_off_outlined,
              message: 'Nenhum módulo combina com a busca.',
              actionLabel: 'Limpar filtros',
              onAction: _controller.clearFilters,
            ),
          );
        }
        return SliverList.separated(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final module = results[index];
            return StudyModuleCard(
              module: module,
              onTap: () => widget.onOpenModule(module),
              trailing: FavoriteButton(
                module: module,
                favorites: widget.favorites,
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        );
    }
  }
}
