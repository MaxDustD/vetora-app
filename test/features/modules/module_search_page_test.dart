import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetora/core/theme/app_theme.dart';
import 'package:vetora/features/favorites/data/favorites_storage.dart';
import 'package:vetora/features/favorites/presentation/favorites_controller.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';
import 'package:vetora/features/modules/domain/module_section.dart';
import 'package:vetora/features/modules/domain/study_module.dart';
import 'package:vetora/features/modules/domain/study_module_repository.dart';
import 'package:vetora/features/modules/presentation/pages/module_search_page.dart';

class _Repository implements StudyModuleRepository {
  @override
  Future<List<StudyModule>> fetchPopular() => fetchAll();

  @override
  Future<List<StudyModule>> fetchAll() async => const [
    StudyModule(
      id: 'calculo',
      title: 'Cálculo 1',
      area: EngineeringArea.mathematics,
      topicCount: 3,
      durationInMinutes: 150,
      resources: {ModuleResource.theory},
    ),
    StudyModule(
      id: 'mecanica',
      title: 'Mecânica clássica',
      subtitle: 'Física 1',
      area: EngineeringArea.physics,
      topicCount: 4,
      durationInMinutes: 180,
      resources: {ModuleResource.theory},
    ),
  ];

  @override
  Future<List<ModuleSection>> fetchSections(String moduleId) async => [];
}

Future<FavoritesController> _pumpSearch(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    FavoritesStorage.favoritesKey: <String>[],
  });
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360, 2400) * 3;
  addTearDown(tester.view.reset);

  final favorites = FavoritesController();
  await favorites.load();
  addTearDown(favorites.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: ModuleSearchPage(
        repository: _Repository(),
        favorites: favorites,
        onOpenModule: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return favorites;
}

void main() {
  testWidgets('debounce espera 300 ms e filtra o catálogo', (tester) async {
    await _pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'mecanica');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cálculo 1'), findsOne);
    expect(find.text('Mecânica clássica'), findsOne);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cálculo 1'), findsNothing);
    expect(find.text('Mecânica clássica'), findsOne);
  });

  testWidgets('limpar filtros restaura o campo e os resultados', (
    tester,
  ) async {
    await _pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'mecanica');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
    expect(find.text('Cálculo 1'), findsOne);
    expect(find.text('Mecânica clássica'), findsOne);
  });

  testWidgets('lista vazia oferece limpar filtros', (tester) async {
    await _pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'biologia');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nenhum módulo combina com a busca.'), findsOne);
    expect(find.text('Limpar filtros'), findsWidgets);
  });
}
