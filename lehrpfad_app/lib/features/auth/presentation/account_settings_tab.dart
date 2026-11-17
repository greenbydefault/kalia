import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../data/auth_providers.dart';
import 'account_prefs_sections.dart';

/// Tab „Einstellungen“: Gruppe, Startpunkt, Abmelden.
class AccountSettingsTab extends ConsumerWidget {
  const AccountSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn =
        SupabaseConfig.isConfigured &&
        ref.watch(authStateProvider).value != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.x5, 20, AppSpacing.x6),
      children: [
        const GroupPrefsSection(),
        const SizedBox(height: AppSpacing.x6),
        const StartpointCard(),
        if (loggedIn) ...[
          const SizedBox(height: AppSpacing.x6),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Abmelden'),
          ),
        ],
      ],
    );
  }
}
