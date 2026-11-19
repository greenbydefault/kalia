import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../../offline/providers/catalog_providers.dart';
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
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.x6),
          const _CatalogSyncDebug(),
        ],
      ],
    );
  }
}

class _CatalogSyncDebug extends ConsumerWidget {
  const _CatalogSyncDebug();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(catalogSyncStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      'Katalog: ${status.trails} Trails · Sync ${status.lastSyncAt ?? 'offen'}'
      '${status.error == null ? '' : '\nFehler: ${status.error}'}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: status.error == null ? null : theme.colorScheme.error,
      ),
    );
  }
}
