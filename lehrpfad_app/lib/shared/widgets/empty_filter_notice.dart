import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'hint_box.dart';

/// Zentrale Leermeldung, wenn Filter keinen Treffer übrig lassen.
/// Überall einsetzen, wo eine Auswahl eine Liste auf null zieht.
class EmptyFilterNotice extends StatelessWidget {
  const EmptyFilterNotice({
    super.key,
    this.message = defaultMessage,
    this.actionLabel,
    this.onAction,
  });

  static const defaultMessage = 'Keine Wege für diese Auswahl.';

  final String message;

  /// Optionaler Ausweg, z. B. „Umkreis vergrößern“.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAction = actionLabel != null && onAction != null;
    return HintBox(
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          if (hasAction) ...[
            const SizedBox(width: AppSpacing.x2),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
