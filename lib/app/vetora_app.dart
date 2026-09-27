import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/startup/presentation/splash_page.dart';

class VetoraApp extends StatelessWidget {
  const VetoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vetora',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark, // tema escuro fixo, independente do sistema
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
