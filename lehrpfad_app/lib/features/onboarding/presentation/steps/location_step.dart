import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../location/location_consent_sheet.dart';

class LocationStep extends StatelessWidget {
  const LocationStep({super.key, required this.onAllow, required this.onSkip});

  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocationConsentCopy.mapTitle,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(LocationConsentCopy.mapBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x5),
        FilledButton(onPressed: onAllow, child: const Text('Erlauben')),
        TextButton(onPressed: onSkip, child: const Text('Nicht jetzt')),
      ],
    );
  }
}
