import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../community/data/community_providers.dart';
import '../../community/presentation/moderation_screen.dart';
import '../../location/location_settings_section.dart';
import '../../onboarding/data/local_guest_profile_store.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../data/auth_providers.dart';
import 'admin_login_section.dart';
import 'auth_form.dart';

/// Account-Inhalt für Tab und Sheet: Login/Register oder Profil.
class AccountPanel extends ConsumerWidget {
  const AccountPanel({super.key, this.padForKeyboard = false});

  /// Extra Bottom-Padding für Modal + Tastatur (Sheet).
  final bool padForKeyboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = padForKeyboard
        ? 24.0 + MediaQuery.of(context).viewInsets.bottom
        : 24.0;
    final guest = ref.watch(guestProfileProvider).asData?.value;

    if (!SupabaseConfig.isConfigured) {
      return _OfflineHint(padBottom: bottom, guest: guest);
    }

    final user = ref.watch(authStateProvider).value;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
      child: user != null
          ? _LoggedInView(user: user)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (guest != null && !guest.isEmpty) ...[
                  _GuestSummary(profile: guest),
                  const SizedBox(height: 16),
                ],
                AuthForm(
                  initialDisplayName: guest?.displayName,
                  belowActions: const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LocationSettingsSection(),
                        SizedBox(height: 32),
                        AdminLoginSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GuestSummary extends StatelessWidget {
  const _GuestSummary({required this.profile});

  final GuestProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kids = profile.childNames.join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile.displayName.isNotEmpty)
          Text(profile.displayName, style: theme.textTheme.titleMedium),
        if (kids.isNotEmpty)
          Text('Kinder: $kids', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          'Konto für Community — Bewertungen und Kommentare. '
          'Fotos gehen auch ohne Anmeldung.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint({required this.padBottom, this.guest});

  final double padBottom;
  final GuestProfile? guest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, padBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Konto', style: theme.textTheme.headlineSmall),
          if (guest != null && !guest!.isEmpty) ...[
            const SizedBox(height: 12),
            _GuestSummary(profile: guest!),
          ],
          const SizedBox(height: 12),
          Text(
            'Offline-Modus: Anmeldung ist ohne Serververbindung nicht '
            'verfügbar. Arten markieren und speichern funktioniert lokal.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const LocationSettingsSection(),
        ],
      ),
    );
  }
}

/// Eingeloggter Zustand: Profil, Moderation (Admin), Abmelden.
class _LoggedInView extends ConsumerWidget {
  final User user;

  const _LoggedInView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final isAdmin = profile?.isAdmin ?? false;
    final guest = ref.watch(guestProfileProvider).asData?.value;
    final kids = guest?.childNames.join(', ') ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                    profile?.displayName.isNotEmpty == true
                        ? profile!.displayName
                        : user.email ?? '',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (kids.isNotEmpty)
                    Text('Kinder: $kids', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ModerationScreen()),
              );
            },
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Moderation'),
          ),
        ],
        const SizedBox(height: 24),
        const LocationSettingsSection(),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Abmelden'),
        ),
      ],
    );
  }
}
