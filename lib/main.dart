import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/vetora_app.dart';

Future<void> main() async {
  // O banco é aberto antes do runApp, que precisa dos canais de plataforma.
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.load();
  runApp(VetoraApp(dependencies: dependencies));
}
