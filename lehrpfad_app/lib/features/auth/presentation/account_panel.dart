import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../../community/data/community_providers.dart';
import '../data/auth_providers.dart';
import 'auth_form.dart';

/// Testversion: Anmelden im Konto-Tab nicht zeigen.
/// Auf `true` stellen, wenn das Formular wieder sichtbar sein soll.
bool get _accountSignInVisible => false;

/// Kopf des Konto-Tabs: Profil mit Zählern oder Login-Formular. Die
/// Inhalte stehen darunter in den Tabs „Meine Beiträge“ und
/// „Einstellungen“.
class AccountPanel extends ConsumerWidget {
  const AccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.isConfigured
        ? ref.watch(authStateProvider).value
        : null;
    final showSignIn = _accountSignInVisible;
    if (user == null && !showSignIn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, AppSpacing.x4),
      child: !SupabaseConfig.isConfigured
          ? const _OfflineHint()
          : user != null
          ? _ProfileHeader(user: user)
          : const AuthForm(),
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
    final stats = ref.watch(myContributionStatsProvider);

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
              Text(
                name.isNotEmpty ? name : user.email ?? '',
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                statsLine(stats),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// „12 Fotos · 3 in Prüfung · 5 Kommentare“; Nullen entfallen.
String statsLine(ContributionStats s) {
  if (s.isEmpty) return 'Noch keine Beiträge';
  final parts = <String>[
    if (s.photos > 0) '${s.photos} ${s.photos == 1 ? 'Foto' : 'Fotos'}',
    if (s.pending > 0) '${s.pending} in Prüfung',
    if (s.rejected > 0) '${s.rejected} abgelehnt',
    if (s.comments > 0)
      '${s.comments} ${s.comments == 1 ? 'Kommentar' : 'Kommentare'}',
  ];
  return parts.join(' · ');
}
