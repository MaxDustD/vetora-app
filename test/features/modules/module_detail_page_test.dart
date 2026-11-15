import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/core/common/formatters.dart';
import 'package:vetora/core/theme/app_theme.dart';
import 'package:vetora/core/widgets/status_views.dart';
import 'package:vetora/features/modules/data/fake_module_content.dart';
import 'package:vetora/features/modules/domain/content_block.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';
import 'package:vetora/features/modules/domain/module_section.dart';
import 'package:vetora/features/modules/domain/study_module.dart';
import 'package:vetora/features/modules/domain/study_module_repository.dart';
import 'package:vetora/features/modules/presentation/pages/module_detail_page.dart';
import 'package:vetora/features/modules/presentation/pages/section_reader_page.dart';
import 'package:vetora/features/modules/presentation/widgets/content_block_view.dart';

/// Cada chamada a [fetchSections] devolve o próximo resultado da lista.
class _StubRepository implements StudyModuleRepository {
  _StubRepository(this._results);

  final List<Future<List<ModuleSection>> Function()> _results;
  int calls = 0;

  @override
  Future<List<StudyModule>> fetchPopular() async => const [];

  @override
  Future<List<StudyModule>> fetchAll() async => const [];

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) =>
      _results[calls++]();
}

const _module = StudyModule(
  id: 'teste',
  title: 'Módulo de teste',
  subtitle: 'Física 1',
  description: 'Descrição do módulo de teste.',
  area: EngineeringArea.physics,
  topicCount: 2,
  durationInMinutes: 90,
  resources: {ModuleResource.theory, ModuleResource.solvedExercises},
);

const _sections = [
  ModuleSection(
    id: 'a',
    title: 'Primeira seção',
    summary: 'Resumo da primeira.',
    blocks: [
      ParagraphBlock('Texto da primeira seção.'),
      FormulaBlock('v = Δs / Δt', caption: 'Velocidade média'),
    ],
  ),
  ModuleSection(
    id: 'b',
    title: 'Segunda seção',
    summary: 'Resumo da segunda.',
    blocks: [
      KeyPointsBlock(title: 'Pontos', items: ['Item um', 'Item dois']),
      ExampleBlock(
        statement: 'Enunciado do exemplo.',
        steps: ['Passo um.', 'Passo dois.'],
        answer: 'Resposta final.',
      ),
    ],
  ),
];

Future<void> _pump(
  WidgetTester tester,
  StudyModuleRepository repo, {
  Widget? trailingAction,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360, 800) * 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: ModuleDetailPage(
        module: _module,
        repository: repo,
        trailingAction: trailingAction,
      ),
    ),
  );
}

void main() {
  testWidgets('mostra o cabeçalho na hora e o esqueleto enquanto carrega', (
    tester,
  ) async {
    final completer = Completer<List<ModuleSection>>();
    await _pump(tester, _StubRepository([() => completer.future]));

    expect(find.text('Módulo de teste'), findsOneWidget);
    expect(find.text('Física 1'), findsOneWidget);
    // Monta o texto com os formatadores (que usam espaço não separável).
    expect(
      find.text(
        '${formatCount(2, 'tópico', 'tópicos')} · ${formatDuration(90)}',
      ),
      findsOneWidget,
    );
    expect(find.text('Descrição do módulo de teste.'), findsOneWidget);
    expect(find.text('Exercícios resolvidos'), findsOneWidget);
    expect(find.byType(SkeletonList), findsOneWidget);

    completer.complete(_sections);
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonList), findsNothing);
    expect(find.text('Primeira seção'), findsOneWidget);
    expect(find.text('Segunda seção'), findsOneWidget);
  });

  testWidgets('sem seções, mostra "em preparação"', (tester) async {
    await _pump(tester, _StubRepository([() async => const []]));
    await tester.pumpAndSettle();
    expect(find.textContaining('em preparação'), findsOneWidget);
  });

  testWidgets('erro mostra mensagem humana e "Tentar novamente" recarrega', (
    tester,
  ) async {
    final repo = _StubRepository([
      () async => throw Exception('falha'),
      () async => _sections,
    ]);
    await _pump(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar o conteúdo.'), findsOneWidget);
    expect(find.textContaining('falha'), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.text('Primeira seção'), findsOneWidget);
  });

  testWidgets('exibe a ação extra na barra do topo', (tester) async {
    await _pump(
      tester,
      _StubRepository([() async => _sections]),
      trailingAction: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.favorite_border),
      ),
    );
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('tocar numa seção abre a leitura; anterior/próxima/concluir', (
    tester,
  ) async {
    await _pump(tester, _StubRepository([() async => _sections]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Primeira seção'));
    await tester.pumpAndSettle();
    expect(find.byType(SectionReaderPage), findsOneWidget);
    expect(find.text('SEÇÃO 1 DE 2'), findsOneWidget);
    expect(find.text('Texto da primeira seção.'), findsOneWidget);
    expect(find.text('v = Δs / Δt'), findsOneWidget);

    // Na primeira seção, "Anterior" fica desabilitado.
    final previous = find.widgetWithText(OutlinedButton, 'Anterior');
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);

    await tester.tap(find.text('Próxima'));
    await tester.pumpAndSettle();
    expect(find.text('SEÇÃO 2 DE 2'), findsOneWidget);
    expect(find.text('Resposta final.'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);

    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('SEÇÃO 1 DE 2'), findsOneWidget);

    await tester.tap(find.text('Próxima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(find.byType(SectionReaderPage), findsNothing);
    expect(find.byType(ModuleDetailPage), findsOneWidget);
  });

  testWidgets('ContentBlockView desenha todos os tipos de bloco', (
    tester,
  ) async {
    final blocks = [..._sections[0].blocks, ..._sections[1].blocks];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ListView(
            children: [for (final b in blocks) ContentBlockView(block: b)],
          ),
        ),
      ),
    );
    expect(find.text('Texto da primeira seção.'), findsOneWidget);
    expect(find.text('Velocidade média'), findsOneWidget);
    expect(find.text('Pontos'), findsOneWidget);
    expect(find.text('Item dois'), findsOneWidget);
    expect(find.text('Passo dois.'), findsOneWidget);
    expect(find.text('RESPOSTA'), findsOneWidget);
  });

  // Material real, tela estreita e fonte ampliada em 2×: nenhuma seção pode
  // transbordar (Unidade 07 — responsividade e acessibilidade).
  testWidgets('material real não transborda com fonte 2×', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(320, 640) * 3;
    addTearDown(tester.view.reset);

    for (final entry in fakeModuleContent.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: 2,
              maxScaleFactor: 2,
              child: SectionReaderPage(
                key: ValueKey('${entry.key}-$i'),
                module: _module,
                sections: entry.value,
                initialIndex: i,
              ),
            ),
          ),
        );
        // Rola até o fim para construir todos os blocos da seção.
        await tester.drag(find.byType(ListView), const Offset(0, -100000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${entry.key} #$i');
      }
    }
  });
}
