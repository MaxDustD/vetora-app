import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/supabase/supabase_config.dart';
import 'app/vetora_app.dart';

Future<void> main() async {
  // Supabase e banco precisam dos canais de plataforma antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseClient = await SupabaseConfig.initialize();
  final dependencies = await AppDependencies.load(
    supabaseClient: supabaseClient,
  );
  runApp(VetoraApp(dependencies: dependencies));
}
