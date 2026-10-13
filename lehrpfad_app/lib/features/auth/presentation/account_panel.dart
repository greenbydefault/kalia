import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../community/data/community_providers.dart';
import '../../location/location_settings_section.dart';
import '../data/auth_providers.dart';
import 'account_prefs_sections.dart';
import 'auth_form.dart';

/// Konto-Tab: Login/Register oder Profil, darunter die lokalen Angaben aus
/// dem Onboarding (Gruppe, Startpunkt, Standort), die ohne Konto gelten.
class AccountPanel extends ConsumerWidget {
  const AccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.isConfigured
        ? ref.watch(authStateProvider).value
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!SupabaseConfig.isConfigured)
            const _OfflineHint()
          else if (user != null)
            _ProfileHeader(user: user)
          else
            const AuthForm(),
          const SizedBox(height: 32),
          const GroupPrefsSection(),
          const SizedBox(height: 24),
          const StartpointSection(),
          const SizedBox(height: 24),
          const LocationSettingsSection(),
          if (user != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Abmelden'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Konto', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          'Offline-Modus: Anmeldung ist ohne Serververbindung nicht '
          'verfügbar. Arten markieren und speichern funktioniert lokal.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(currentProfileProvider).value?.displayName ?? '';

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Angemeldet als', style: theme.textTheme.bodySmall),
              Text(
                name.isNotEmpty ? name : user.email ?? '',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
