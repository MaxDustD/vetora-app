// Gera supabase/02_seed.sql a partir do catálogo de demonstração do app, para
// que o Supabase e o SQLite local tenham exatamente os mesmos dados.
//
// Uso (na raiz do projeto):
//   dart run tool/generate_supabase_seed.dart > supabase/02_seed.sql
import 'dart:convert';
import 'dart:io';

import 'package:vetora/features/modules/data/content_block_codec.dart';
import 'package:vetora/features/modules/data/fake_module_content.dart';
import 'package:vetora/features/modules/data/fake_study_module_repository.dart';
import 'package:vetora/features/modules/data/module_storage_keys.dart';

/// Dados que só existem no banco remoto (o app ainda não os exibe).
const _ratings = {
  'calculo-1': 4.8,
  'mecanica-classica': 4.7,
  'circuitos-eletricos': 4.5,
  'resistencia-dos-materiais': 4.3,
  'termodinamica': 4.1,
  'eletromagnetismo': 3.9,
};

/// UUIDs fixos: prefixo por tabela + contador, para testes e relacionamentos.
String _uuid(String prefix, int n) =>
    '$prefix-0000-4000-8000-${n.toString().padLeft(12, '0')}';

String _text(String value) => "'${value.replaceAll("'", "''")}'";

void main() {
  const modules = FakeStudyModuleRepository.modules;
  final out = StringBuffer()
    ..writeln('''
-- =============================================================================
-- Vetora — 02_seed.sql
-- Massa de dados do catálogo: ${modules.length} módulos, seus detalhes, seções e blocos.
--
-- ARQUIVO GERADO por tool/generate_supabase_seed.dart a partir dos mesmos
-- dados que o app grava no SQLite local. Para mudar o conteúdo, edite
-- lib/features/modules/data/ e rode:
--   dart run tool/generate_supabase_seed.dart > supabase/02_seed.sql
--
-- UUIDs determinísticos (prefixo = tabela):
--   a0000000-… study_modules      d0000000-… study_module_details
--   b0000000-… module_sections    c0000000-… content_blocks
--
-- Idempotente: "on conflict (id) do nothing" permite rodar de novo.
-- Execute DEPOIS do 01_schema.sql (no SQL Editor, que usa a service_role).
-- =============================================================================

begin;
''');

  // ---------------------------------------------------------------- módulos
  out.writeln('-- 1. Módulos (entidade principal)');
  out.writeln('insert into public.study_modules');
  out.writeln(
    '  (id, slug, title, subtitle, area, topic_count, '
    'duration_in_minutes, resources, average_rating, popularity_rank, '
    'cover_image_path)',
  );
  out.writeln('values');
  out.writeln(
    [
      for (final (i, m) in modules.indexed)
        "  ('${_uuid('a0000000', i + 1)}', ${_text(m.id)}, ${_text(m.title)}, "
            '${_text(m.subtitle)}, ${_text(ModuleStorageKeys.areas[m.area]!)}, '
            '${m.topicCount}, ${m.durationInMinutes}, '
            "array[${ModuleStorageKeys.sqlList(m.resources.map((r) => ModuleStorageKeys.resources[r]!))}]::text[], "
            '${_ratings[m.id] ?? 'null'}, ${i + 1}, '
            "${_text('${m.id}/capa.png')})",
    ].join(',\n'),
  );
  out.writeln('on conflict (id) do nothing;\n');

  // --------------------------------------------------------------- detalhes
  // Só módulos com apresentação têm detalhe: a relação 1:1 é opcional.
  out.writeln('-- 2. Detalhes 1:1 (só os módulos que já têm apresentação)');
  out.writeln(
    'insert into public.study_module_details (id, module_id, description)',
  );
  out.writeln('values');
  out.writeln(
    [
      for (final (i, m) in modules.indexed)
        if (m.description.isNotEmpty)
          "  ('${_uuid('d0000000', i + 1)}', '${_uuid('a0000000', i + 1)}',\n"
              '   ${_text(m.description)})',
    ].join(',\n'),
  );
  out.writeln('on conflict (id) do nothing;\n');

  // ------------------------------------------------------ seções e blocos
  final sectionRows = <String>[];
  final blockRows = <String>[];
  var sectionCount = 0;
  var blockCount = 0;
  for (final (i, m) in modules.indexed) {
    for (final (position, s) in (fakeModuleContent[m.id] ?? const []).indexed) {
      final sectionId = _uuid('b0000000', ++sectionCount);
      sectionRows.add(
        "  ('$sectionId', '${_uuid('a0000000', i + 1)}', ${_text(s.id)}, "
        '$position, ${_text(s.title)},\n   ${_text(s.summary)})',
      );
      for (final (blockPosition, b) in s.blocks.indexed) {
        blockRows.add(
          "  ('${_uuid('c0000000', ++blockCount)}', '$sectionId', $blockPosition, "
          "'${ContentBlockCodec.typeOf(b)}',\n"
          '   ${_text(jsonEncode(ContentBlockCodec.payloadOf(b)))}::jsonb)',
        );
      }
    }
  }

  out.writeln('-- 3. Seções (filhas 1:N dos módulos)');
  out.writeln(
    'insert into public.module_sections '
    '(id, module_id, slug, position, title, summary)',
  );
  out.writeln('values');
  out.writeln(sectionRows.join(',\n'));
  out.writeln('on conflict (id) do nothing;\n');

  out.writeln('-- 4. Blocos de conteúdo (filhos 1:N das seções)');
  out.writeln(
    'insert into public.content_blocks '
    '(id, section_id, position, kind, payload)',
  );
  out.writeln('values');
  out.writeln(blockRows.join(',\n'));
  out.writeln('on conflict (id) do nothing;\n');

  final detailCount = modules.where((m) => m.description.isNotEmpty).length;
  out.writeln('''
commit;

-- =============================================================================
-- Conferência: a coluna "ok" deve ser true em todas as linhas.
-- =============================================================================
select 'study_modules' as tabela, count(*) as total, ${modules.length} as esperado,
       count(*) = ${modules.length} as ok
  from public.study_modules
union all
select 'study_module_details', count(*), $detailCount, count(*) = $detailCount
  from public.study_module_details
union all
select 'module_sections', count(*), $sectionCount, count(*) = $sectionCount
  from public.module_sections
union all
select 'content_blocks', count(*), $blockCount, count(*) = $blockCount
  from public.content_blocks;''');

  stdout.write(out);
}
