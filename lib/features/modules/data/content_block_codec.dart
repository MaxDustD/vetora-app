import '../domain/content_block.dart';

/// Converte um [ContentBlock] em `tipo + dados` e de volta.
///
/// Os quatro tipos de bloco têm campos diferentes; em vez de uma tabela por
/// tipo, o banco guarda o tipo numa coluna e os campos num JSON. O mesmo
/// formato é usado no SQLite do app e no script do Supabase (`supabase/`).
abstract final class ContentBlockCodec {
  static const paragraph = 'paragraph';
  static const formula = 'formula';
  static const keyPoints = 'key_points';
  static const example = 'example';

  /// Valores aceitos na coluna `type` (o `CHECK` das tabelas usa a mesma lista).
  static const types = [paragraph, formula, keyPoints, example];

  static String typeOf(ContentBlock block) => switch (block) {
    ParagraphBlock() => paragraph,
    FormulaBlock() => formula,
    KeyPointsBlock() => keyPoints,
    ExampleBlock() => example,
  };

  static Map<String, Object?> payloadOf(ContentBlock block) => switch (block) {
    ParagraphBlock(:final text) => {'text': text},
    FormulaBlock(:final expression, :final caption) => {
      'expression': expression,
      'caption': ?caption,
    },
    KeyPointsBlock(:final title, :final items) => {
      'title': title,
      'items': items,
    },
    ExampleBlock(:final statement, :final steps, :final answer) => {
      'statement': statement,
      'steps': steps,
      'answer': answer,
    },
  };

  /// Lança [FormatException] para um tipo desconhecido: um dado corrompido
  /// aparece como erro na tela, e não como um bloco vazio silencioso.
  static ContentBlock decode(String type, Map<String, Object?> payload) {
    List<String> strings(String key) =>
        (payload[key] as List<Object?>).cast<String>();

    return switch (type) {
      paragraph => ParagraphBlock(payload['text'] as String),
      formula => FormulaBlock(
        payload['expression'] as String,
        caption: payload['caption'] as String?,
      ),
      keyPoints => KeyPointsBlock(
        title: payload['title'] as String,
        items: strings('items'),
      ),
      example => ExampleBlock(
        statement: payload['statement'] as String,
        steps: strings('steps'),
        answer: payload['answer'] as String,
      ),
      _ => throw FormatException('Tipo de bloco desconhecido: $type'),
    };
  }
}
