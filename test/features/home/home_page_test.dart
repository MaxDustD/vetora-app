import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/core/storage/profile_storage.dart';
import 'package:vetora/core/theme/app_theme.dart';
import 'package:vetora/features/home/presentation/pages/home_page.dart';
import 'package:vetora/core/widgets/status_views.dart';
import 'package:vetora/features/home/presentation/widgets/profile_prompt_card.dart';
import 'package:vetora/features/home/presentation/widgets/study_focus_card.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';
import 'package:vetora/features/modules/domain/module_section.dart';
import 'package:vetora/features/modules/domain/study_module.dart';
import 'package:vetora/features/modules/domain/study_module_repository.dart';
import 'package:vetora/features/modules/presentation/widgets/study_module_card.dart';

/// Repositório substituto: cada chamada devolve o próximo resultado da lista
/// e [calls] conta quantas vezes a tela pediu dados.
///
/// Guarda funções que criam Futures (e não Futures prontos): um Future com
/// erro criado antes da hora viraria um erro "não tratado".
class _StubRepository implements StudyModuleRepository {
  _StubRepository(this._results);

  final List<Future<List<StudyModule>> Function()> _results;
  int calls = 0;

  @override
  Future<List<StudyModule>> fetchPopular() => _results[calls++]();

  @override
  Future<List<StudyModule>> fetchAll() => fetchPopular();

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) async => [];
}

const _mechanics = StudyModule(
  id: '1',
  title: 'Mecânica de teste',
  area: EngineeringArea.physics,
  topicCount: 12,
  durationInMinutes: 90,
  resources: {ModuleResource.theory},
);

const _circuits = StudyModule(
  id: '2',
  title: 'Circuitos de teste',
  area: EngineeringArea.electrical,
  topicCount: 1,
  durationInMinutes: 45,
  resources: {ModuleResource.theory, ModuleResource.calculator},
);

Future<void> _pumpHome(
  WidgetTester tester,
  StudyModuleRepository repo, {
  UserProfile profile = const UserProfile(),
  VoidCallback? onOpenProfile,
  Size size = const Size(360, 800),
  double textScale = 1,
}) {
  // Celular de 360 × 800 dp (o padrão do ambiente de teste é 800 × 600).
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: Scaffold(
          body: HomePage(
            repository: repo,
            profile: profile,
            onOpenProfile: onOpenProfile,
            clock: () => DateTime(2026, 1, 1, 9),
          ),
        ),
      ),
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra carregamento e depois os módulos', (tester) async {
    // O Completer segura a resposta: dá para ver o esqueleto antes dos dados.
    final completer = Completer<List<StudyModule>>();
    final repo = _StubRepository([() => completer.future]);
    await _pumpHome(tester, repo);

    await _scrollTo(tester, find.byType(SkeletonList));
    expect(find.byType(SkeletonList), findsOne);

    completer.complete([_mechanics]);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Mecânica de teste'));

    expect(find.byType(SkeletonList), findsNothing);
    expect(
      find.text('Física · 12\u00A0tópicos · 1\u00A0h 30\u00A0min'),
      findsOne,
    );
    expect(find.text('Teoria'), findsOne);
  });

  testWidgets('mostra a saudação conforme o relógio injetado', (tester) async {
    final repo = _StubRepository([() async => []]);
    await _pumpHome(tester, repo, profile: const UserProfile(name: 'Alex'));
    await tester.pumpAndSettle();

    expect(find.text('BOM DIA, ALEX'), findsOne);
  });

  testWidgets('mostra mensagem quando não há módulos', (tester) async {
    final repo = _StubRepository([() async => []]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    final message = find.text('Ainda não há módulos disponíveis.');
    await _scrollTo(tester, message);
    expect(message, findsOne);
  });

  testWidgets('mostra erro e permite tentar novamente', (tester) async {
    final repo = _StubRepository([
      () async => throw Exception('sem conexão'),
      () async => [_mechanics],
    ]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    final retry = find.text('Tentar novamente');
    await _scrollTo(tester, retry);
    expect(find.text('Não foi possível carregar os módulos.'), findsOne);
    // O erro técnico nunca chega à tela.
    expect(find.textContaining('sem conexão'), findsNothing);

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('Mecânica de teste'), findsOne);
  });

  testWidgets('puxar para atualizar busca de novo sem esconder a lista', (
    tester,
  ) async {
    final repo = _StubRepository([
      () async => [_mechanics],
      () async => [_mechanics, _circuits],
    ]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    expect(find.byType(SkeletonList), findsNothing);
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    await _scrollTo(tester, find.text('Circuitos de teste'));
    expect(find.text('Circuitos de teste'), findsOne);
  });

  testWidgets('não busca de novo quando a tela é reconstruída', (tester) async {
    final repo = _StubRepository([
      () async => [_mechanics],
    ]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    // Bombear a mesma árvore de novo força um novo build() da HomePage.
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    expect(repo.calls, 1);
  });

  testWidgets('filtra pela área tocada e desfaz o filtro', (tester) async {
    final repo = _StubRepository([
      () async => [_mechanics, _circuits],
    ]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Elétrica'));
    await tester.tap(find.text('Elétrica'));
    await tester.pumpAndSettle();

    expect(find.text('Módulos de Engenharia Elétrica'), findsOne);
    expect(find.byType(StudyModuleCard), findsOne);
    expect(find.text('Mecânica de teste'), findsNothing);

    await tester.tap(find.text('Limpar filtro'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyModuleCard), findsNWidgets(2));
  });

  testWidgets('área sem módulos explica e oferece limpar o filtro', (
    tester,
  ) async {
    final repo = _StubRepository([
      () async => [_mechanics],
    ]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Civil'));
    await tester.tap(find.text('Civil'));
    await tester.pumpAndSettle();

    final message = find.text('Ainda não há módulos de Engenharia Civil.');
    await _scrollTo(tester, message);
    expect(message, findsOne);
  });

  testWidgets('prioriza os módulos das áreas de interesse do perfil', (
    tester,
  ) async {
    final repo = _StubRepository([
      () async => [_mechanics, _circuits],
    ]);
    await _pumpHome(
      tester,
      repo,
      profile: const UserProfile(
        name: 'Alex',
        preferences: ['Engenharia Elétrica'],
      ),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Circuitos de teste'));

    final cards = tester.widgetList<StudyModuleCard>(
      find.byType(StudyModuleCard),
    );
    expect(cards.first.module, _circuits);
  });

  testWidgets('perfil incompleto mostra o convite, que abre o perfil', (
    tester,
  ) async {
    var opened = 0;
    final repo = _StubRepository([() async => []]);
    await _pumpHome(tester, repo, onOpenProfile: () => opened++);
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePromptCard), findsOne);
    expect(find.byType(StudyFocusCard), findsNothing);

    await tester.tap(find.text('Completar perfil'));
    expect(opened, 1);
  });

  testWidgets('perfil completo troca o convite pelo foco de estudo', (
    tester,
  ) async {
    final repo = _StubRepository([() async => []]);
    await _pumpHome(
      tester,
      repo,
      profile: const UserProfile(name: 'Alex', preferences: ['Física']),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePromptCard), findsNothing);
    expect(find.byType(StudyFocusCard), findsOne);
  });

  testWidgets('toques sem destino ainda dão feedback "em breve"', (
    tester,
  ) async {
    final repo = _StubRepository([() async => []]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buscar conceitos, fórmulas ou matérias'));
    await tester.pump();
    expect(find.text('A busca estará disponível em breve.'), findsOne);
  });

  testWidgets('segue as regras de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = _StubRepository([
      () async => [_mechanics, _circuits],
    ]);
    await _pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  for (final width in [320.0, 800.0]) {
    testWidgets('sem overflow com fonte a 200% em ${width.toInt()} dp', (
      tester,
    ) async {
      final repo = _StubRepository([
        () async => [_mechanics, _circuits],
      ]);
      await _pumpHome(tester, repo, size: Size(width, 800), textScale: 2);
      await tester.pumpAndSettle();

      // Rola a tela inteira: um overflow em qualquer bloco falha o teste.
      await _scrollTo(tester, find.text('Circuitos de teste'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('em tela larga, o conteúdo fica limitado a 600 dp', (
    tester,
  ) async {
    final repo = _StubRepository([
      () async => [_mechanics],
    ]);
    await _pumpHome(tester, repo, size: const Size(1000, 800));
    await tester.pumpAndSettle();

    final card = tester.getSize(find.byType(ProfilePromptCard));
    expect(card.width, HomePage.maxContentWidth);
  });
}
