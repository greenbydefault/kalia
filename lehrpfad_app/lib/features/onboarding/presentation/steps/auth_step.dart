import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/auth_form.dart';

class AuthStep extends StatelessWidget {
  const AuthStep({
    super.key,
    this.initialDisplayName,
    required this.startInRegisterMode,
    required this.onSuccess,
    required this.onContinueWithoutAccount,
  });

  final String? initialDisplayName;
  final bool startInRegisterMode;
  final VoidCallback onSuccess;
  final VoidCallback onContinueWithoutAccount;

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Konto', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Offline-Modus: Anmeldung ist ohne Serververbindung nicht '
            'verfügbar. Du kannst ohne Konto weiter.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x5),
          FilledButton(
            onPressed: onContinueWithoutAccount,
            child: const Text('Ohne Konto weiter'),
          ),
        ],
      );
    }

    return AuthForm(
      initialDisplayName: initialDisplayName,
      startInRegisterMode: startInRegisterMode,
      onSuccess: onSuccess,
      aboveFields: const _SsoStubs(),
      belowActions: TextButton(
        onPressed: onContinueWithoutAccount,
        child: const Text('Lieber ohne Konto weiter'),
      ),
    );
  }
}

class _SsoStubs extends StatelessWidget {
  const _SsoStubs();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _soon(context, 'Google'),
          icon: const PhosphorIcon(PhosphorIcons.googleLogo, size: 20),
          label: const Text('Weiter mit Google'),
        ),
        const SizedBox(height: AppSpacing.x2),
        OutlinedButton.icon(
          onPressed: () => _soon(context, 'Apple'),
          icon: const PhosphorIcon(PhosphorIcons.appleLogo, size: 20),
          label: const Text('Weiter mit Apple'),
        ),
      ],
    );
  }

  void _soon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider-Anmeldung kommt in Kürze.')),
    );
  }
}
