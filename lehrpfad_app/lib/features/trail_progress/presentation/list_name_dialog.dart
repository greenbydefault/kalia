import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/hybrid_trail_list_repository.dart';

Future<String?> showListNameDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String confirmLabel = 'Anlegen',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: HybridTrailListRepository.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'z. B. Wasserspielplätze',
            counterText: '',
          ),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isEmpty) return;
            Navigator.of(dialogContext).pop(name);
          },
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          0,
          AppSpacing.x4,
          AppSpacing.x3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogContext).pop(name);
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  ).whenComplete(() {
    controller.dispose();
  });
}
