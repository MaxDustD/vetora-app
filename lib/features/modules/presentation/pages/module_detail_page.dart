import 'package:flutter/material.dart';

import '../../../../core/common/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_views.dart';
import '../../domain/module_section.dart';
import '../../domain/study_module.dart';
import '../../domain/study_module_repository.dart';
import '../engineering_area_icon.dart';
import '../widgets/resource_badge.dart';
import 'section_reader_page.dart';

/// Tela de um módulo: apresentação e índice do material.
///
/// Hierarquia: 1. o que é (área, título, subtítulo) → 2. quanto exige
/// (tópicos, duração) → 3. por que estudar (descrição, recursos) →
/// 4. conteúdo (seções, na ordem de estudo).
///
/// O cabeçalho usa o [module] recebido e aparece na hora; só as seções vêm
/// do [repository], com os mesmos estados da Home (carregando → erro →
/// vazio → dados).
class ModuleDetailPage extends StatefulWidget {
  const ModuleDetailPage({
    super.key,
    required this.module,
    required this.repository,
    this.trailingAction,
  });

  final StudyModule module;
  final StudyModuleRepository repository;

  /// Ação extra na barra do topo (ex.: o botão de favoritar).
  final Widget? trailingAction;

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<ModuleDetailPage> {
  /// Criado no initState (não no build), para não refazer a busca a cada
  /// reconstrução.
  late Future<List<ModuleSection>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = widget.repository.fetchSections(widget.module.id);
  }

  void _reload() {
    setState(() {
      _sectionsFuture = widget.repository.fetchSections(widget.module.id);
    });
  }

  void _openSection(List<ModuleSection> sections, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SectionReaderPage(
          module: widget.module,
          sections: sections,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );
    final action = widget.trailingAction;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            // O título só aparece na barra como referência curta; o título
            // completo está no cabeçalho logo abaixo.
            title: Text(
              widget.module.area.label.toUpperCase(),
              style: AppTextStyles.rotulo,
            ),
            actions: [
              ?action,
              const SizedBox(width: AppSpacing.sm),
            ],
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
                _ModuleHeader(module: widget.module),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Conteúdo',
                  subtitle: 'Siga as seções na ordem sugerida',
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
            sliver: _buildSections(),
          ),
        ],
      ),
    );
  }

  Widget _buildSections() {
    return FutureBuilder<List<ModuleSection>>(
      future: _sectionsFuture,
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData;
        if (isLoading) {
          return const SliverToBoxAdapter(
            child: SkeletonList(
              semanticLabel: 'Carregando conteúdo',
              itemHeight: 76,
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: StatusMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Não foi possível carregar o conteúdo.',
              actionLabel: 'Tentar novamente',
              onAction: _reload,
            ),
          );
        }

        final sections = snapshot.data ?? const <ModuleSection>[];
        if (sections.isEmpty) {
          return const SliverToBoxAdapter(
            child: StatusMessage(
              icon: Icons.edit_note_outlined,
              message:
                  'O material deste módulo está em preparação. '
                  'Volte em breve!',
            ),
          );
        }

        return SliverList.separated(
          itemCount: sections.length,
          itemBuilder: (context, index) => _SectionTile(
            number: index + 1,
            section: sections[index],
            onTap: () => _openSection(sections, index),
          ),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        );
      },
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.module});

  final StudyModule module;

  @override
  Widget build(BuildContext context) {
    final details = [
      formatCount(module.topicCount, 'tópico', 'tópicos'),
      formatDuration(module.durationInMinutes),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.superficieElevada,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: ExcludeSemantics(
            child: Icon(module.area.icon, color: AppColors.ciano, size: 28),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(module.title, style: AppTextStyles.titulo),
        ),
        if (module.subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            module.subtitle,
            style: AppTextStyles.secao.copyWith(color: AppColors.ciano),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(details, style: AppTextStyles.apoio),
        if (module.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(module.description, style: AppTextStyles.corpo),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final resource in module.resources)
              ResourceBadge(resource: resource),
          ],
        ),
      ],
    );
  }
}

/// Item do índice: número da seção, título e resumo.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.number,
    required this.section,
    required this.onTap,
  });

  final int number;
  final ModuleSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Um único item para o leitor de tela: "Seção 1, Definição de função…".
    return MergeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Seção $number',
                  excludeSemantics: true,
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ciano,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: AppTextStyles.tituloCartao),
                      const SizedBox(height: AppSpacing.xs),
                      Text(section.summary, style: AppTextStyles.apoio),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textoTerciario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
