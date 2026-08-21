import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class FamilyStep extends StatelessWidget {
  const FamilyStep({
    super.key,
    required this.nameController,
    required this.childControllers,
    required this.onAddChild,
    required this.onRemoveChild,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final List<TextEditingController> childControllers;
  final VoidCallback onAddChild;
  final ValueChanged<int> onRemoveChild;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Wer seid ihr?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Optional — kannst du auch leer lassen.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Dein Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text('Kinder', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.x2),
        for (var i = 0; i < childControllers.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: childControllers[i],
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Name des Kindes',
                    border: const OutlineInputBorder(),
                    suffixIcon: childControllers.length > 1
                        ? IconButton(
                            tooltip: 'Entfernen',
                            onPressed: () => onRemoveChild(i),
                            icon: const Icon(Icons.close),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAddChild,
            icon: const Icon(Icons.add),
            label: const Text('Kind hinzufügen'),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.n100,
            borderRadius: BorderRadius.circular(AppSpacing.x2),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Text(
              'Zu den Lehrpfaden und Stationen gibt es oft keine '
              'vollständigen, zentral gepflegten Daten. Wir arbeiten an der '
              'Genauigkeit, können aber nicht zu 100 % garantieren, dass '
              'alles stimmt. Wenn dir ein Fehler auffällt, meld ihn uns gern.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x5),
        FilledButton(onPressed: onContinue, child: const Text('Weiter')),
      ],
    );
  }
}
