import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import 'admin_app.dart';
import 'auth/admin_session.dart';

/// Einstieg des Admin-CMS (eigenes Web-Target):
/// `flutter run -d chrome -t lib/admin/admin_main.dart --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(
      MaterialApp(
        theme: adminTheme(),
        home: const Scaffold(
          body: Center(
            child: Text(
              'SUPABASE_URL und SUPABASE_PUBLISHABLE_KEY fehlen '
              '(--dart-define).',
            ),
          ),
        ),
      ),
    );
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final session = AdminSession(Supabase.instance.client);
  runApp(ProviderScope(child: AdminApp(session: session)));
}
