import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future<void>.delayed(
      const Duration(seconds: 2),
    );
  }
}

@override
Widget build(BuildContext context) {
  return const Scaffold(
    body: Center(
      child: Text(
        'Vetora',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
