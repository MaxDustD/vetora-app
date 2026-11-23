import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static Future<SupabaseClient> initialize() async {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY usando --dart-define.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
    return Supabase.instance.client;
  }
}
