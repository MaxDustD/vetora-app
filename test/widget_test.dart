import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetora/app/app_routes.dart';
import 'package:vetora/app/vetora_app.dart';
import 'package:vetora/core/storage/onboarding_storage.dart';
import 'package:vetora/app/shell/app_shell.dart';
import 'package:vetora/features/calculator/presentation/calculator_page.dart';
import 'package:vetora/features/favorites/data/favorites_storage.dart';
import 'package:vetora/features/modules/presentation/pages/module_detail_page.dart';
import 'package:vetora/features/home/presentation/pages/home_page.dart';
import 'package:vetora/features/home/presentation/widgets/study_focus_card.dart';
import 'package:vetora/features/onboarding/presentation/onboarding_page.dart';
import 'package:vetora/features/startup/presentation/splash_page.dart';

/// Cenários de validação do fluxo inicial e das telas principais.
void main() {
  /// O repositório falso da AppShell tem 800 ms de atraso: avança o relógio
  /// até a lista chegar, para não deixar timers pendentes no fim do teste.
  Future<void> settleHome(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Finder navDestination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Future<bool?> storedValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(OnboardingStorage.onboardingCompletedKey);
  }

  testWidgets('Cenário A — primeira execução: Splash → Onboarding → Home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Engenharia começa com boas ideias.'), findsOneWidget);

    // Página 1 → 2 deslizando; 2 → 3 pelo botão de avançar.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Conecte a teoria à prática.'), findsOneWidget);

    await tester.tap(find.byTooltip('Próxima etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Estude no seu ritmo.'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);

    await tester.tap(find.text('Começar →'));
    await tester.pumpAndSettle();
    await settleHome(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('O que vamos aprender hoje?'), findsOneWidget);
    for (final area in ['Física', 'Civil', 'Elétrica', 'Mecânica']) {
      await tester.scrollUntilVisible(find.text(area), 200);
      expect(find.text(area), findsOneWidget);
    }
    expect(await storedValue(), isTrue);
    // Pilha limpa: o voltar da Home fecha o app (Cenário F).
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('Cenário B — execução posterior: Splash → Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingStorage.onboardingCompletedKey: true,
    });

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await settleHome(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('O que vamos aprender hoje?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(navDestination('Calculadora'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorPage), findsOneWidget);
    expect(find.text('Gráfico'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('Voltar do Android em outra aba retorna ao Início', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      OnboardingStorage.onboardingCompletedKey: true,
    });

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await settleHome(tester);

    await tester.tap(navDestination('Favoritos'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Favoritar na Home aparece na aba Favoritos', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingStorage.onboardingCompletedKey: true,
    });

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await settleHome(tester);

    final heart = find.byTooltip('Adicionar Cálculo 1 aos favoritos');
    await tester.scrollUntilVisible(heart, 200);
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(find.text('Cálculo 1 adicionado aos favoritos.'), findsOneWidget);

    await tester.tap(navDestination('Favoritos'));
    await settleHome(tester);

    expect(find.text('1\u00A0MÓDULO GUARDADO'), findsOneWidget);
    expect(find.byTooltip('Remover Cálculo 1 dos favoritos'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(FavoritesStorage.favoritesKey), ['calculo-1']);
  });

  testWidgets('Tocar em um módulo abre a tela dele; voltar retorna à Home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      OnboardingStorage.onboardingCompletedKey: true,
    });

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await settleHome(tester);

    final card = find.text('Mecânica clássica');
    await tester.scrollUntilVisible(card, 200);
    await tester.tap(card);
    await settleHome(tester);
    expect(find.byType(ModuleDetailPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ModuleDetailPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('A aba Início preserva a rolagem ao trocar de aba', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      OnboardingStorage.onboardingCompletedKey: true,
    });

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await settleHome(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0));

    await tester.tap(navDestination('Calculadora'));
    await tester.pumpAndSettle();
    await tester.tap(navDestination('Início'));
    await tester.pumpAndSettle();

    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      offset,
    );
  });

  testWidgets('Perfil salvo personaliza a Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingStorage.onboardingCompletedKey: true,
    });

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await settleHome(tester);
    await tester.tap(navDestination('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Programação'), findsNothing);
    expect(find.text('Termodinâmica'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tester.ensureVisible(find.text('Física'));
    await tester.tap(find.text('Física'));
    await tester.pump();
    await tester.ensureVisible(find.text('Salvar perfil'));
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil atualizado com sucesso.'), findsOneWidget);
    await tester.tap(navDestination('Início'));
    await tester.pumpAndSettle();

    // A saudação depende da hora real ("BOM DIA, ALEX", "BOA TARDE, ALEX"...).
    expect(find.textContaining(', ALEX'), findsOneWidget);
    expect(find.text('Completar perfil'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(StudyFocusCard),
        matching: find.text('Física'),
      ),
      findsOneWidget,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_name'), 'Alex');
    expect(prefs.getStringList('profile_preferences'), ['Física']);
  });

  testWidgets('Cenário C — "Pular" na página 1 conclui o onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    await settleHome(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(await storedValue(), isTrue);
  });

  testWidgets('Voltar do Android na página 2 retorna à página 1', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Próxima etapa'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Engenharia começa com boas ideias.'), findsOneWidget);
    expect(await storedValue(), isNull);
  });

  testWidgets('Falha na leitura é tratada como onboarding não concluído', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.splash: (_) => const SplashPage(storage: _FailingStorage()),
          AppRoutes.onboarding: (_) => const Text('onboarding'),
          AppRoutes.home: (_) => const Text('home'),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('onboarding'), findsOneWidget);
  });
}

class _FailingStorage extends OnboardingStorage {
  const _FailingStorage();

  @override
  Future<bool> isCompleted() => Future.error(Exception('falha de leitura'));
}
