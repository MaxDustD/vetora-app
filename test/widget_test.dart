import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetora/app/app_routes.dart';
import 'package:vetora/app/vetora_app.dart';
import 'package:vetora/core/storage/onboarding_storage.dart';
import 'package:vetora/features/home/presentation/home_page.dart';
import 'package:vetora/features/onboarding/presentation/onboarding_page.dart';
import 'package:vetora/features/startup/presentation/splash_page.dart';

/// Cenários de validação do Trabalho 1, seção 11.
void main() {
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
    expect(find.text('Cálculos complexos, mais simples.'), findsOneWidget);

    // Página 1 → 2 deslizando; 2 → 3 pelo botão de avançar.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Do problema ao resultado.'), findsOneWidget);

    await tester.tap(find.byTooltip('Próxima etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Precisão sem distrações.'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);

    await tester.tap(find.text('Começar →'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
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

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(SplashPage), findsNothing);
  });

  testWidgets('Cenário C — "Pular" na página 1 conclui o onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VetoraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

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

    expect(find.text('Cálculos complexos, mais simples.'), findsOneWidget);
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
