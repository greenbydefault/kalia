import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/opening_hours.dart';

/// Kompakter Status aus [openingHours]; unsichtbar wenn nicht auswertbar.
class OeffnungsBadge extends StatelessWidget {
  const OeffnungsBadge({super.key, required this.openingHours});

  final String? openingHours;

  @override
  Widget build(BuildContext context) {
    final status = oeffnungsStatus(openingHours, DateTime.now());
    if (status == OeffnungsStatus.unbekannt) {
      return const SizedBox.shrink();
    }
    final open = status == OeffnungsStatus.offen;
    return Text(
      open ? 'Jetzt geöffnet' : 'Geschlossen',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: open ? AppColors.eignung5 : AppColors.inkMuted,
      ),
    );
  }
}
