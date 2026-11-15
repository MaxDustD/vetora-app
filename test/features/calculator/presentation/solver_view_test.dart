import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/core/theme/app_theme.dart';
import 'package:vetora/features/calculator/graphing/presentation/graphing_calculator_view.dart';
import 'package:vetora/features/calculator/presentation/calculator_page.dart';
import 'package:vetora/features/calculator/presentation/solver/solver_view.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 800),
  double textScale = 1,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: Scaffold(body: child),
      ),
    ),
  );
}

Finder _field(String label) => find.widgetWithText(TextField, label);

void main() {
  testWidgets('calcula uma expressão e mostra o resultado exato', (
    tester,
  ) async {
    await _pump(tester, const SolverView());
    await tester.enterText(_field('Expressão'), '1/3 + 0,25');
    await tester.tap(find.widgetWithText(FilledButton, 'Calcular'));
    await tester.pump();

    expect(find.text('RESULTADO'), findsOneWidget);
    expect(find.text('7/12'), findsOneWidget);
    expect(find.text('≈ 0,5833333333'), findsOneWidget);
  });

  testWidgets('erro de digitação aparece no campo, sem resultado', (
    tester,
  ) async {
    await _pump(tester, const SolverView());
    await tester.enterText(_field('Expressão'), '(2+3');
    await tester.tap(find.widgetWithText(FilledButton, 'Calcular'));
    await tester.pump();

    expect(find.textContaining('não foi fechado'), findsOneWidget);
    expect(find.text('RESULTADO'), findsNothing);
  });

  testWidgets('derivar mostra os campos de ordem e ponto e o passo a passo', (
    tester,
  ) async {
    await _pump(tester, const SolverView());
    await tester.tap(find.widgetWithText(ChoiceChip, 'Derivar'));
    await tester.pump();

    expect(find.text('ORDEM'), findsOneWidget);
    await tester.enterText(_field('f(x)'), 'x^3');
    await tester.tap(find.byTooltip('Aumentar ordem'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Derivar'));
    await tester.pump();

    expect(find.text('6x'), findsOneWidget);
    expect(find.text('PASSO A PASSO'), findsOneWidget);
  });

  testWidgets('integral definida com limites e selo de aproximação', (
    tester,
  ) async {
    await _pump(tester, const SolverView());
    await tester.tap(find.widgetWithText(ChoiceChip, 'Integrar'));
    await tester.pump();
    await tester.enterText(_field('f(x)'), 'e^(-x^2)');
    await tester.enterText(_field('De'), '-∞');
    await tester.enterText(_field('Até'), '∞');
    await tester.tap(find.widgetWithText(FilledButton, 'Integrar'));
    await tester.pump();

    expect(find.text('1,772453851'), findsOneWidget);
    expect(find.text('Aproximação numérica'), findsOneWidget);
  });

  testWidgets('limite lateral', (tester) async {
    await _pump(tester, const SolverView());
    await tester.tap(find.widgetWithText(ChoiceChip, 'Limite'));
    await tester.pump();
    await tester.enterText(_field('f(x)'), '1/x');
    await tester.tap(find.text('x → a⁺'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Limite'));
    await tester.pump();

    expect(find.text('+∞'), findsOneWidget);
  });

  testWidgets('atalho insere a função com o cursor dentro dos parênteses', (
    tester,
  ) async {
    await _pump(tester, const SolverView());
    await tester.tap(_field('Expressão'));
    await tester.tap(find.bySemanticsLabel('Inserir seno'));
    await tester.pump();
    await tester.enterText(_field('Expressão'), 'sen(π/2)');
    await tester.tap(find.widgetWithText(FilledButton, 'Calcular'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('cabe em 320 dp com fonte 2× em todas as operações', (
    tester,
  ) async {
    await _pump(
      tester,
      const SolverView(),
      size: const Size(320, 640),
      textScale: 2,
    );
    for (final label in ['Derivar', 'Integrar', 'Limite', 'Taylor']) {
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('CalculatorPage alterna entre Cálculos e Gráfico', (
    tester,
  ) async {
    await _pump(tester, const CalculatorPage());
    expect(find.byType(SolverView), findsOneWidget);

    await tester.tap(find.text('Gráfico'));
    await tester.pump();
    final graph = find.byType(GraphingCalculatorView);
    expect(graph, findsOneWidget);
    // IndexedStack: o gráfico fica visível e o solver continua montado.
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
      1,
    );
    expect(tester.takeException(), isNull);
  });
}
