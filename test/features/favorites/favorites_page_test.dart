import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetora/core/theme/app_theme.dart';
import 'package:vetora/features/favorites/data/favorites_storage.dart';
import 'package:vetora/features/favorites/presentation/favorites_controller.dart';
import 'package:vetora/features/favorites/presentation/favorites_page.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';
import 'package:vetora/features/modules/domain/module_section.dart';
import 'package:vetora/features/modules/domain/study_module.dart';
import 'package:vetora/features/modules/domain/study_module_repository.dart';
import 'package:vetora/features/modules/presentation/widgets/study_module_card.dart';

class _StubRepository implements StudyModuleRepository {
  _StubRepository(this._results);

  final List<Future<List<StudyModule>> Function()> _results;
  int calls = 0;

  @override
  Future<List<StudyModule>> fetchAll() => _results[calls++]();

  @override
  Future<List<StudyModule>> fetchPopular() => fetchAll();

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) async => [];
}

StudyModule _module(String id, String title) => StudyModule(
  id: id,
  title: title,
  area: EngineeringArea.mathematics,
  topicCount: 3,
  durationInMinutes: 60,
  resources: const {ModuleResource.theory},
);

final _calculo = _module('calculo-1', 'Cálculo 1');
final _fisica = _module('fisica', 'Mecânica clássica');

Future<FavoritesController> _pumpFavorites(
  WidgetTester tester,
  StudyModuleRepository repo, {
  List<String> saved = const [],
  VoidCallback? onExplore,
  ValueChanged<StudyModule>? onOpenModule,
}) async {
  SharedPreferences.setMockInitialValues({
    FavoritesStorage.favoritesKey: saved,
  });
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360, 800) * 3;
  addTearDown(tester.view.reset);

  final favorites = FavoritesController();
  addTearDown(favorites.dispose);
  await favorites.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: FavoritesPage(
          repository: repo,
          favorites: favorites,
          onOpenModule: onOpenModule ?? (_) {},
          onExplore: onExplore ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return favorites;
}

void main() {
  testWidgets('sem favoritos, explica e leva a explorar', (tester) async {
    var explored = 0;
    await _pumpFavorites(
      tester,
      _StubRepository([
        () async => [_calculo],
      ]),
      onExplore: () => explored++,
    );

    expect(find.textContaining('Você ainda não tem favoritos'), findsOne);
    await tester.tap(find.text('Explorar módulos'));
    expect(explored, 1);
  });

  testWidgets('lista os favoritos do mais recente para o mais antigo', (
    tester,
  ) async {
    await _pumpFavorites(
      tester,
      _StubRepository([
        () async => [_calculo, _fisica],
      ]),
      saved: ['fisica', 'calculo-1', 'removido-do-catalogo'],
    );

    final cards = tester
        .widgetList<StudyModuleCard>(find.byType(StudyModuleCard))
        .map((card) => card.module.id);
    expect(cards, ['fisica', 'calculo-1']);
    expect(find.text('2 MÓDULOS GUARDADOS'), findsOne);
  });

  testWidgets('tocar no cartão abre o módulo', (tester) async {
    StudyModule? opened;
    await _pumpFavorites(
      tester,
      _StubRepository([
        () async => [_calculo],
      ]),
      saved: ['calculo-1'],
      onOpenModule: (module) => opened = module,
    );

    await tester.tap(find.text('Cálculo 1'));
    expect(opened, _calculo);
  });

  testWidgets('remover pelo coração tira o cartão e permite desfazer', (
    tester,
  ) async {
    final favorites = await _pumpFavorites(
      tester,
      _StubRepository([
        () async => [_calculo],
      ]),
      saved: ['calculo-1'],
    );

    await tester.tap(find.byTooltip('Remover Cálculo 1 dos favoritos'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyModuleCard), findsNothing);
    expect(find.text('Cálculo 1 removido dos favoritos.'), findsOne);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    expect(favorites.isFavorite('calculo-1'), isTrue);
    expect(find.byType(StudyModuleCard), findsOne);
  });

  testWidgets('a confirmação de favorito some sozinha depois de um tempo', (
    tester,
  ) async {
    await _pumpFavorites(
      tester,
      _StubRepository([
        () async => [_calculo],
      ]),
      saved: ['calculo-1'],
    );

    await tester.tap(find.byTooltip('Remover Cálculo 1 dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Cálculo 1 removido dos favoritos.'), findsOne);

    // Duração da SnackBar (4 s) + animação de saída.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Cálculo 1 removido dos favoritos.'), findsNothing);
  });

  testWidgets('erro ao carregar o catálogo permite tentar novamente', (
    tester,
  ) async {
    final repo = _StubRepository([
      () async => throw Exception('sem conexão'),
      () async => [_calculo],
    ]);
    await _pumpFavorites(tester, repo, saved: ['calculo-1']);

    expect(find.text('Não foi possível carregar seus favoritos.'), findsOne);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('Cálculo 1'), findsOne);
  });
}
