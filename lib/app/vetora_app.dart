import 'package:flutter/material.dart';

import '../features/startup/presentation/splash_page.dart';

class VetoraApp extends StatelessWidget {
  const VetoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vetora',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
