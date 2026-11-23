import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/storage/onboarding_storage.dart';
import '../../../../core/storage/profile_storage.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_views.dart';
import '../../../../core/widgets/vetora_header.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../modules/domain/engineering_area.dart';
import '../../../modules/domain/study_module.dart';
import '../../../modules/domain/study_module_repository.dart';
import '../../../modules/presentation/widgets/study_module_card.dart';
import '../greeting.dart';
import '../module_ordering.dart';
import '../widgets/area_shortcuts.dart';
import '../widgets/home_header.dart';
import '../widgets/profile_prompt_card.dart';
import '../widgets/search_entry.dart';
import '../widgets/study_focus_card.dart';

/// Aba "Início": o resumo do dia e o ponto de partida.
///
/// Hierarquia: 1. contexto (saudação) → 2. ação principal (busca) →
/// 3. próximo passo (perfil) → 4. atalhos (áreas) → 5. conteúdo (módulos).
///
/// Não tem Scaffold: é o conteúdo de uma aba do [AppShell], que fornece a
/// barra de navegação e o ScaffoldMessenger.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    this.profile = const UserProfile(),
    this.onOpenProfile,
    this.favorites,
    this.onOpenModule,
    this.onOpenSearch,
    this.onboardingStorage = const OnboardingStorage(),
    this.clock = DateTime.now,
  });

  /// Contrato dos dados; a implementação concreta vem da raiz de composição.
  final StudyModuleRepository repository;
  final UserProfile profile;

  /// Leva à aba Perfil. Sem ele, o cartão de perfil mostra "em breve".
  final VoidCallback? onOpenProfile;

  /// Favoritos compartilhados. Sem eles, os cartões não mostram o coração.
  final FavoritesController? favorites;

  /// Abre a tela do módulo. Sem ele, o toque mostra "em breve".
  final ValueChanged<StudyModule>? onOpenModule;

  /// Abre a tela própria de busca. Sem ela, o toque mostra "em breve".
  final VoidCallback? onOpenSearch;

  /// Usado só pelo botão de depuração "Redefinir primeiro acesso".
  final OnboardingStorage onboardingStorage;

  /// Relógio injetável, para testar a saudação sem depender da hora real.
  final DateTime Function() clock;

  /// Largura máxima de leitura (limite da classe de janela "compact").
  static const double maxContentWidth = AppLayout.maxContentWidth;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Criado uma vez no initState e trocado só ao recarregar. Criá-lo no build
  /// faria uma nova busca a cada reconstrução.
  late Future<List<StudyModule>> _modulesFuture;

  /// Área escolhida nos atalhos; `null` mostra todas.
  EngineeringArea? _selectedArea;

  @override
  void initState() {
    super.initState();
    _modulesFuture = widget.repository.fetchPopular();
  }

  void _reload() {
    // Chaves, e não `=>`: o callback do setState não pode devolver o Future.
    setState(() {
      _modulesFuture = widget.repository.fetchPopular();
    });
  }

  /// Para o "puxar para atualizar": espera o mesmo Future entregue ao
  /// FutureBuilder, sem disparar uma segunda busca.
  Future<void> _refresh() async {
    _reload();
    try {
      await _modulesFuture;
    } catch (_) {
      // O erro já é exibido pelo FutureBuilder; aqui só paramos o indicador.
    }
  }

  void _toggleArea(EngineeringArea area) {
    setState(() => _selectedArea = _selectedArea == area ? null : area);
  }

  void _clearFilter() => setState(() => _selectedArea = null);

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showComingSoon(String feature) {
    _showMessage('$feature estará disponível em breve.');
  }

  Future<void> _resetFirstAccess() async {
    await widget.onboardingStorage.reset();
    if (!mounted) return;
    _showMessage(
      'Primeiro acesso redefinido. Reabra o app para ver o onboarding.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Em telas largas, o conteúdo fica com até 600 dp, centralizado; a área
    // de rolagem continua ocupando a tela toda.
    final horizontalPadding = AppLayout.horizontalPadding(screenWidth);
    final profile = widget.profile;
    final openProfile =
        widget.onOpenProfile ?? () => _showComingSoon('O perfil');
    final area = _selectedArea;

    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: CustomScrollView(
        // Permite puxar para atualizar mesmo quando o conteúdo cabe na tela.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(
            pinned: true,
            titleSpacing: AppSpacing.lg,
            title: VetoraHeader(),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.sm,
              horizontalPadding,
              0,
            ),
            sliver: SliverList.list(
              children: [
                HomeHeader(
                  greeting: greetingFor(widget.clock()),
                  name: profile.name,
                ),
                const SizedBox(height: AppSpacing.lg),
                SearchEntry(
                  onTap:
                      widget.onOpenSearch ?? () => _showComingSoon('A busca'),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (profile.isComplete)
                  StudyFocusCard(
                    preferences: profile.preferences,
                    onEdit: openProfile,
                  )
                else
                  ProfilePromptCard(onPressed: openProfile),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Explore por área',
                  subtitle: 'Toque em uma área para filtrar os módulos',
                ),
                const SizedBox(height: AppSpacing.sm),
                AreaShortcuts(selected: area, onSelected: _toggleArea),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Mais estudados',
                  subtitle: area == null
                      ? 'Temas populares entre estudantes de engenharia'
                      : 'Módulos de ${area.label}',
                  actionLabel: area == null ? 'Ver todos' : 'Limpar filtro',
                  onAction: area == null
                      ? () => _showComingSoon('A lista completa')
                      : _clearFilter,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.xl,
            ),
            sliver: _buildModules(),
          ),
          if (kDebugMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Center(
                  child: TextButton(
                    onPressed: _resetFirstAccess,
                    child: const Text('REDEFINIR PRIMEIRO ACESSO (DEBUG)'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Os quatro estados da lista, nesta ordem: carregando → erro → vazio →
  /// dados. Todos os retornos são slivers.
  Widget _buildModules() {
    return FutureBuilder<List<StudyModule>>(
      future: _modulesFuture,
      builder: (context, snapshot) {
        // Ao recarregar com dados já na tela, mantém a lista visível em vez de
        // voltar ao esqueleto. Vem antes do erro: o snapshot guarda o erro
        // anterior durante uma nova tentativa.
        final isLoading =
            snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData;
        if (isLoading) {
          return const SliverToBoxAdapter(
            child: SkeletonList(semanticLabel: 'Carregando módulos'),
          );
        }

        if (snapshot.hasError) {
          // Nunca mostrar snapshot.error ao usuário: a mensagem é humana.
          return SliverToBoxAdapter(
            child: StatusMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Não foi possível carregar os módulos.',
              actionLabel: 'Tentar novamente',
              onAction: _reload,
            ),
          );
        }

        final area = _selectedArea;
        final modules = arrangeModules(
          snapshot.data ?? const <StudyModule>[],
          area: area,
          interests: widget.profile.preferences,
        );

        if (modules.isEmpty) {
          return SliverToBoxAdapter(
            child: area == null
                ? const StatusMessage(
                    icon: Icons.search_off_outlined,
                    message: 'Ainda não há módulos disponíveis.',
                  )
                : StatusMessage(
                    icon: Icons.search_off_outlined,
                    message: 'Ainda não há módulos de ${area.label}.',
                    actionLabel: 'Limpar filtro',
                    onAction: _clearFilter,
                  ),
          );
        }

        final favorites = widget.favorites;
        final openModule = widget.onOpenModule;

        // Construída sob demanda: só os cartões perto da área visível.
        return SliverList.separated(
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return StudyModuleCard(
              module: module,
              onTap: openModule == null
                  ? () => _showComingSoon('O módulo ${module.title}')
                  : () => openModule(module),
              trailing: favorites == null
                  ? null
                  : FavoriteButton(module: module, favorites: favorites),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        );
      },
    );
  }
}
