import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/module_section.dart';
import '../../domain/study_module.dart';
import '../widgets/content_block_view.dart';

/// Leitura de uma seção do módulo, com navegação para a anterior e a próxima.
///
/// Recebe a lista já carregada pela [ModuleDetailPage]: trocar de seção não
/// faz nova busca. Na última seção, o botão principal vira "Concluir" e volta
/// ao índice do módulo.
class SectionReaderPage extends StatefulWidget {
  const SectionReaderPage({
    super.key,
    required this.module,
    required this.sections,
    this.initialIndex = 0,
  }) : assert(sections.length > 0),
       assert(initialIndex >= 0 && initialIndex < sections.length);

  final StudyModule module;
  final List<ModuleSection> sections;
  final int initialIndex;

  @override
  State<SectionReaderPage> createState() => _SectionReaderPageState();
}

class _SectionReaderPageState extends State<SectionReaderPage> {
  late int _index = widget.initialIndex;

  bool get _isFirst => _index == 0;
  bool get _isLast => _index == widget.sections.length - 1;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final section = widget.sections[_index];
    final total = widget.sections.length;
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.module.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tituloCartao,
        ),
      ),
      body: ListView(
        // Chave por seção: ao trocar de seção, a rolagem volta ao topo em vez
        // de manter a posição do texto anterior.
        key: ValueKey(section.id),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.sm,
          horizontalPadding,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'SEÇÃO ${_index + 1} DE $total',
            style: AppTextStyles.rotulo.copyWith(color: AppColors.ciano),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            header: true,
            child: Text(section.title, style: AppTextStyles.titulo),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(section.summary, style: AppTextStyles.corpo),
          const SizedBox(height: AppSpacing.lg),
          for (final block in section.blocks) ...[
            ContentBlockView(block: block),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
      bottomNavigationBar: _ReaderNavigation(
        horizontalPadding: horizontalPadding,
        hasPrevious: !_isFirst,
        isLast: _isLast,
        onPrevious: () => _goTo(_index - 1),
        onNext: _isLast
            ? () => Navigator.of(context).pop()
            : () => _goTo(_index + 1),
      ),
    );
  }
}

class _ReaderNavigation extends StatelessWidget {
  const _ReaderNavigation({
    required this.horizontalPadding,
    required this.hasPrevious,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
  });

  final double horizontalPadding;

  final bool hasPrevious;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borda)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm + AppSpacing.xs,
            horizontalPadding,
            AppSpacing.sm + AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasPrevious ? onPrevious : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brancoTecnico,
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: AppColors.borda),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppTextStyles.botao,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNext,
                  // Ícone depois do texto: indica "seguir em frente".
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(isLast ? 'Concluir' : 'Próxima'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
