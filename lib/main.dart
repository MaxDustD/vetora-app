import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_dependencies.dart';
import 'app/config/supabase_config.dart';
import 'app/vetora_app.dart';
import 'features/modules/data/supabase_study_module_repository.dart';

Future<void> main() async {
  // Necessário antes de qualquer plugin (o Supabase guarda a sessão no aparelho).
  WidgetsFlutterBinding.ensureInitialized();

  final config = SupabaseConfig.fromEnvironment();
  final problems = config.problems;
  if (problems.isNotEmpty) {
    throw StateError(
      'Configuração do Supabase incompleta:\n'
      '- ${problems.join('\n- ')}\n'
      'Rode com: flutter run --dart-define-from-file=.env '
      '(modelo em .env.example).',
    );
  }

  await Supabase.initialize(
    url: config.normalizedUrl,
    publishableKey: config.publishableKey,
  );

  final repository = SupabaseStudyModuleRepository(Supabase.instance.client);
  final dependencies = await AppDependencies.load(repository: repository);
  runApp(VetoraApp(dependencies: dependencies));
}
