import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/content_block.dart';

/// Desenha um [ContentBlock] do material de estudo.
///
/// O `switch` sobre a classe `sealed` é exaustivo: um tipo novo de bloco no
/// domínio não compila até ganhar o seu visual aqui.
class ContentBlockView extends StatelessWidget {
  const ContentBlockView({super.key, required this.block});

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      ParagraphBlock(:final text) => Text(text, style: _leitura),
      FormulaBlock(:final expression, :final caption) => _FormulaView(
        expression: expression,
        caption: caption,
      ),
      KeyPointsBlock(:final title, :final items) => _KeyPointsView(
        title: title,
        items: items,
      ),
      ExampleBlock(:final statement, :final steps, :final answer) =>
        _ExampleView(statement: statement, steps: steps, answer: answer),
    };
  }
}

/// Texto corrido em branco técnico: na leitura longa, o contraste maior que o
/// do texto secundário cansa menos.
final _leitura = AppTextStyles.corpo.copyWith(color: AppColors.brancoTecnico);

/// Fórmula em JetBrains Mono, a fonte dos dados (Trabalho 1, seção 03).
class _FormulaView extends StatelessWidget {
  const _FormulaView({required this.expression, this.caption});

  final String expression;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final label = caption;
    // O recorte arredonda os cantos; a borda só à esquerda (filete ciano)
    // destaca a fórmula sem criar outra cor de acento.
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.superficieElevada,
          border: Border(left: BorderSide(color: AppColors.ciano, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expression,
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.brancoTecnico,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTextStyles.apoio),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyPointsView extends StatelessWidget {
  const _KeyPointsView({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.tituloCartao),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.only(top: 9, right: AppSpacing.sm),
                    child: Icon(Icons.circle, size: 6, color: AppColors.ciano),
                  ),
                ),
                Expanded(child: Text(item, style: _leitura)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Exemplo resolvido: enunciado → passos numerados → resposta. A resposta usa
/// a borda verde de "resultado validado" (Trabalho 1, seção 03).
class _ExampleView extends StatelessWidget {
  const _ExampleView({
    required this.statement,
    required this.steps,
    required this.answer,
  });

  final String statement;
  final List<String> steps;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        const Text('EXEMPLO RESOLVIDO', style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Text(statement, style: AppTextStyles.tituloCartao),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}.',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.ciano,
                    ),
                  ),
                ),
                Expanded(child: Text(steps[i], style: _leitura)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.grafite,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.verdeConfirmacao),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RESPOSTA', style: AppTextStyles.rotulo),
              const SizedBox(height: AppSpacing.xs),
              Text(
                answer,
                style: _leitura.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painel com o visual dos cartões (superfície + borda de 1 px).
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
