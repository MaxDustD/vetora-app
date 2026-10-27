import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/startup/presentation/splash_page.dart';
import 'app_routes.dart';

class VetoraApp extends StatelessWidget {
  const VetoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vetora',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark, // tema escuro fixo, independente do sistema
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<void>? _onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.splash => const SplashPage(),
      AppRoutes.onboarding => const OnboardingPage(),
      AppRoutes.home => const HomePage(),
      _ => const SplashPage(),
    };

    // Todas as telas têm o mesmo fundo grafite: um fade de 300 ms preserva a
    // sensação de continuidade (Trabalho 1, seção 06).
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
