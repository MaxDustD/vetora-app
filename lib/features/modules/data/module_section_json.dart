import '../domain/module_section.dart';
import 'content_block_codec.dart';

/// Converte linhas de seções e seus blocos agrupados, ordenando por posição.
List<ModuleSection> moduleSectionsFromJson(
  List<Map<String, dynamic>> rows,
  Map<String, List<Map<String, dynamic>>> blocksBySection,
) {
  final sectionRows = [...rows]
    ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  return [
    for (final row in sectionRows)
      _moduleSectionFromJson(
        row,
        blocksBySection[row['id'] as String] ?? const [],
      ),
  ];
}

ModuleSection _moduleSectionFromJson(
  Map<String, dynamic> json,
  List<Map<String, dynamic>> rows,
) {
  final blockRows = [...rows]
    ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  return ModuleSection(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    blocks: List.unmodifiable([
      for (final row in blockRows)
        ContentBlockCodec.decode(
          row['kind'] as String,
          (row['payload'] as Map).cast<String, Object?>(),
        ),
    ]),
  );
}
