/// Formatação de números para pessoas (pt-BR).
///
/// Entre número e unidade usamos o espaço não separável (` `), que impede
/// "45" no fim de uma linha e "min" sozinho no começo da seguinte.
library;

/// `90` → `1 h 30 min`; `45` → `45 min`; `120` → `2 h`.
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}

/// `1` → `1 tópico`; `12` → `12 tópicos`.
String formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}
