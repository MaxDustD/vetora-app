/// Bloco de conteúdo de uma seção de estudo.
///
/// `sealed`: o conjunto de tipos de bloco é fechado, e o `switch` que os
/// desenha na apresentação é verificado pelo compilador. Um tipo novo de
/// bloco obriga a tratar o seu visual.
sealed class ContentBlock {
  const ContentBlock();
}

/// Texto corrido.
class ParagraphBlock extends ContentBlock {
  const ParagraphBlock(this.text);

  final String text;
}

/// Fórmula em destaque, escrita em texto (ex.: `v = v₀ + a·t`).
class FormulaBlock extends ContentBlock {
  const FormulaBlock(this.expression, {this.caption});

  final String expression;

  /// Nome ou explicação curta da fórmula ("Equação de Torricelli").
  final String? caption;
}

/// Lista de pontos-chave (regras, definições, tabelas curtas).
class KeyPointsBlock extends ContentBlock {
  const KeyPointsBlock({required this.title, required this.items});

  final String title;
  final List<String> items;
}

/// Exemplo resolvido: enunciado, passos e resposta.
class ExampleBlock extends ContentBlock {
  const ExampleBlock({
    required this.statement,
    required this.steps,
    required this.answer,
  });

  final String statement;
  final List<String> steps;
  final String answer;
}
