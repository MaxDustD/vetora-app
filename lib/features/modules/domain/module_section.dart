import 'content_block.dart';

/// Uma seção do material de um módulo (ex.: "Limite e continuidade").
class ModuleSection {
  const ModuleSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.blocks,
  });

  final String id;
  final String title;

  /// Uma frase sobre o que a seção ensina, mostrada no índice do módulo.
  final String summary;
  final List<ContentBlock> blocks;
}
