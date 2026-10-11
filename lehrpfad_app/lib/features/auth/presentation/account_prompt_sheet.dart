import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../data/auth_providers.dart';
import 'auth_form.dart';

/// Begründungen im Kontext. Das Konto wird erst gefragt, wenn es gebraucht
/// wird (Just-in-time).
abstract final class AccountReason {
  static const photo =
      'Zum Hochladen von Fotos braucht ihr ein Konto, damit eure Bilder '
      'euch gehören und ihr sie wiederfindet.';
  static const rate =
      'Zum Bewerten braucht ihr ein Konto, damit jede Familie nur einmal '
      'zählt.';
  static const comment =
      'Zum Kommentieren braucht ihr ein Konto, damit andere wissen, '
      'von wem der Tipp kommt.';
  static const savedList =
      'Mit einem Konto bleibt eure Merkliste auch beim Handywechsel erhalten.';
}

/// Stellt sicher, dass ein Konto da ist. Fragt bei Bedarf mit [reason].
///
/// Liefert `true`, wenn danach ein Nutzer angemeldet ist. Ohne Server
/// (Offline-Seed) gibt es keine Konten, dann kommt nur ein Hinweis.
Future<bool> requireAccount(
  BuildContext context, {
  required String reason,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (!SupabaseConfig.isConfigured) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Ein Konto gibt es nur mit Serververbindung.'),
      ),
    );
    return false;
  }
  if (container.read(authStateProvider).value != null) return true;

  await showAppModalSheet<bool>(
    context: context,
    padForKeyboard: true,
    builder: (_) => AccountPromptSheet(reason: reason),
  );
  return container.read(authStateProvider).value != null;
}

/// Konto-Abfrage als Sheet: Begründung, Formular, „Später“.
class AccountPromptSheet extends StatelessWidget {
  const AccountPromptSheet({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Konto erstellen', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.x2),
        Text(reason, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x4),
        AuthForm(
          showHeadline: false,
          startInRegisterMode: true,
          onSuccess: () => Navigator.of(context).pop(true),
          belowActions: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Später'),
          ),
        ),
      ],
    );
  }
}

/// Bottom-Sheet bei wachsender Merkliste (einmalig).
Future<void> showSavedListSheet(BuildContext context) async {
  final create = await showAppModalSheet<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Eure Merkliste wächst', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Mit einem Konto bleibt sie auch beim Handywechsel erhalten, '
            'und ihr könnt Fotos teilen. Ohne Konto funktioniert weiterhin '
            'alles.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x5),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Konto erstellen'),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Später'),
          ),
        ],
      );
    },
  );
  if (create == true && context.mounted) {
    await requireAccount(context, reason: AccountReason.savedList);
  }
}
