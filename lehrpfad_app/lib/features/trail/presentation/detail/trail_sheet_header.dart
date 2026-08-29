import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/catalogs/icon_catalog.dart';
import '../../../../shared/widgets/bottom_content_card.dart';
import '../../domain/trail.dart';

/// Griff, Typ-Chips, Peek-CTAs, Titel und Kurzbeschreibung des Trail-Sheets.
class TrailSheetHeader extends StatelessWidget {
  const TrailSheetHeader({
    super.key,
    required this.trail,
    required this.onClose,
    this.peekActions,
    this.showClose = true,
    this.showHandle = true,
  });

  final Trail trail;
  final VoidCallback onClose;
  final Widget? peekActions;
  final bool showClose;

  /// Drag-Griff oben — nur für Bottom-Sheets, nicht in der Detail-Seite.
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typ = typEintrag(trail.typ);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHandle || showClose)
          _SheetHandle(
            onClose: onClose,
            showClose: showClose,
            showHandle: showHandle,
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  Chip(
                    label: Text(typ.label),
                    avatar: typ.buildIcon(size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (trail.isFlaeche)
                    const Chip(
                      label: Text('Platz'),
                      avatar: Icon(Icons.park_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                    )
                  else if (trail.rundkurs)
                    const Chip(
                      label: Text('Rundkurs'),
                      avatar: Icon(Icons.loop, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (trail.eintritt)
                    const Chip(
                      label: Text('Eintritt'),
                      avatar: PhosphorIcon(PhosphorIcons.ticket, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            if (peekActions != null) ...[
              const SizedBox(width: AppSpacing.x2),
              Flexible(flex: 0, fit: FlexFit.loose, child: peekActions!),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          trail.name.toUpperCase(),
          style: theme.textTheme.headlineSmall?.copyWith(fontSize: 48),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(trail.kurzbeschreibung, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({
    required this.onClose,
    required this.showClose,
    required this.showHandle,
  });

  final VoidCallback onClose;
  final bool showClose;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showHandle) const BottomContentCardHandle(),
          if (showClose)
            Positioned(
              right: 0,
              child: IconButton(
                tooltip: 'Schließen',
                icon: const PhosphorIcon(PhosphorIcons.x, size: 20),
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
