import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({
    super.key,
    required this.onContinueWithoutAccount,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  final VoidCallback onContinueWithoutAccount;
  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kalia', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.x1),
        Text('Lehrpfade mit Kindern', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Finde Naturlehrpfade in der Nähe. Ein Konto brauchst du nur, '
          'wenn du Teil der Community sein willst.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.x5),
        _ChoiceCard(
          title: 'Ohne Konto weiter',
          body: 'Karte, Touren, Merken und Sammlung bleiben auf dem Gerät.',
          onTap: onContinueWithoutAccount,
          filled: true,
        ),
        const SizedBox(height: AppSpacing.x3),
        _ChoiceCard(
          title: 'Konto erstellen',
          body: 'Fotos hochladen, bewerten, kommentieren — Community.',
          onTap: onCreateAccount,
          filled: false,
        ),
        TextButton(
          onPressed: onSignIn,
          child: const Text('Schon ein Konto? Anmelden'),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.body,
    required this.onTap,
    required this.filled,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Padding(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: filled ? AppColors.paper : AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: filled ? AppColors.onImage70 : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );

    if (filled) {
      return Material(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppSpacing.x3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.x3),
          child: child,
        ),
      );
    }

    return Material(
      color: AppColors.n100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.x3),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.x3),
        child: child,
      ),
    );
  }
}
