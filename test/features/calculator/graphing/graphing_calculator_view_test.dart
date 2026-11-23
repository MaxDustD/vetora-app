import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/core/theme/app_theme.dart';
import 'package:vetora/features/calculator/graphing/presentation/graph_painter.dart';
import 'package:vetora/features/calculator/graphing/presentation/graphing_calculator_view.dart';

Future<void> _pumpGraph(
  WidgetTester tester, {
  List<String>? expressions,
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
        child: Scaffold(
          body: GraphingCalculatorView(initialExpressions: expressions),
        ),
      ),
    ),
  );
}

final _graphFinder = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is GraphPainter,
);

GraphPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_graphFinder).painter! as GraphPainter;

void main() {
  testWidgets('começa desenhando sen(x)', (tester) async {
    await _pumpGraph(tester);

    expect(find.text('sen(x)'), findsOne);
    expect(find.text('f(x) ='), findsOne);
    expect(_painter(tester).curves, hasLength(1));
  });

  testWidgets('expressão inválida mostra o erro e não desenha', (
    tester,
  ) async {
    await _pumpGraph(tester, expressions: ['x^2']);
    expect(_painter(tester).curves, hasLength(1));

    await tester.enterText(find.byType(TextField), '2*(x+');
    await tester.pump();

    expect(_painter(tester).curves, isEmpty);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.errorText, isNotNull);
  });

  testWidgets('aceita só a variável x', (tester) async {
    await _pumpGraph(tester, expressions: ['']);

    await tester.enterText(find.byType(TextField), 'x + y');
    await tester.pump();

    expect(find.textContaining('Use apenas a variável x'), findsOne);
    expect(_painter(tester).curves, isEmpty);
  });

  testWidgets('campo vazio não é erro', (tester) async {
    await _pumpGraph(tester, expressions: ['']);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.errorText, isNull);
    expect(_painter(tester).curves, isEmpty);
  });

  testWidgets('adiciona até quatro funções, cada uma com seu nome', (
    tester,
  ) async {
    await _pumpGraph(tester, expressions: ['x']);

    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('Adicionar função'));
      await tester.tap(find.text('Adicionar função'));
      await tester.pump();
    }

    expect(find.byType(TextField), findsNWidgets(4));
    for (final name in ['f', 'g', 'h', 'p']) {
      expect(find.text('$name(x) ='), findsOne);
    }
    expect(find.text('Adicionar função'), findsNothing);
  });

  testWidgets('remover mantém o nome e a cor das outras funções', (
    tester,
  ) async {
    await _pumpGraph(tester, expressions: ['x', 'x^2', 'x^3']);

    await tester.tap(find.byTooltip('Remover g(x)'));
    await tester.pump();

    expect(find.text('g(x) ='), findsNothing);
    expect(find.text('f(x) ='), findsOne);
    expect(find.text('h(x) ='), findsOne);
    final colors = _painter(tester).curves.map((c) => c.color);
    expect(colors, [
      GraphingCalculatorView.colors[0],
      GraphingCalculatorView.colors[2],
    ]);
  });

  testWidgets('remover a única função só limpa o campo', (tester) async {
    await _pumpGraph(tester, expressions: ['x']);

    await tester.tap(find.byTooltip('Remover f(x)'));
    await tester.pump();

    expect(find.byType(TextField), findsOne);
    expect(_painter(tester).curves, isEmpty);
  });

  testWidgets('atalhos inserem no cursor e fecham o parêntese', (
    tester,
  ) async {
    await _pumpGraph(tester, expressions: ['']);

    await tester.tap(find.byTooltip('Inserir sen'));
    await tester.pump();
    await tester.tap(find.byTooltip('Inserir x'));
    await tester.pump();

    expect(find.text('sen(x)'), findsOne);
    expect(_painter(tester).curves, hasLength(1));
  });

  testWidgets('botões de zoom e centralizar mudam a janela', (tester) async {
    await _pumpGraph(tester);
    final initialWidth = _painter(tester).viewport.width;

    await tester.tap(find.byTooltip('Aproximar'));
    await tester.pump();
    expect(_painter(tester).viewport.width, closeTo(initialWidth / 1.5, 1e-9));

    await tester.tap(find.byTooltip('Afastar'));
    await tester.tap(find.byTooltip('Afastar'));
    await tester.pump();
    expect(_painter(tester).viewport.width, closeTo(initialWidth * 1.5, 1e-9));

    await tester.tap(find.byTooltip('Centralizar'));
    await tester.pump();
    expect(_painter(tester).viewport.width, closeTo(initialWidth, 1e-9));
  });

  testWidgets('arrastar desloca o plano', (tester) async {
    await _pumpGraph(tester);
    final before = _painter(tester).viewport;

    await tester.drag(_graphFinder, const Offset(-100, 0));
    await tester.pump();

    final after = _painter(tester).viewport;
    expect(after.xMin, greaterThan(before.xMin));
    expect(after.width, closeTo(before.width, 1e-9));
  });

  testWidgets('tocar no gráfico mostra o valor de cada função', (
    tester,
  ) async {
    await _pumpGraph(tester, expressions: ['2x', 'x^2']);
    expect(find.textContaining('Toque no gráfico'), findsOne);

    // Centro do gráfico: x = 0 (a janela inicial é simétrica).
    await tester.tapAt(tester.getCenter(_graphFinder));
    await tester.pump();

    expect(_painter(tester).traceX, closeTo(0, 1e-9));
    expect(find.text('x = 0'), findsOne);
    expect(find.text('f(x) = 0'), findsOne);
    expect(find.text('g(x) = 0'), findsOne);

    await tester.tap(find.byTooltip('Remover leitura'));
    await tester.pump();
    expect(_painter(tester).traceX, isNull);
  });

  testWidgets('segue as regras de acessibilidade', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpGraph(tester, expressions: ['x^2', 'sen(x)']);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    expect(
      find.bySemanticsLabel(RegExp(r'^Gráfico de f\(x\) = .*; g\(x\) = ')),
      findsOne,
    );
    handle.dispose();
  });

  testWidgets('sem overflow com fonte a 200% em 320 dp', (tester) async {
    await _pumpGraph(
      tester,
      expressions: ['x^2', 'sen(x)', '1/x'],
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.tapAt(tester.getCenter(_graphFinder));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
