import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/widgets/status_toggle.dart';

/// Toggle „Hab gesehen“.
class GesehenToggle extends StatelessWidget {
  const GesehenToggle({
    super.key,
    required this.seen,
    required this.onChanged,
    this.iconOnly = false,
  });

  final bool seen;
  final ValueChanged<bool> onChanged;

  /// Kompakt ohne Label — für Peek-Kacheln.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return StatusToggle(
      selected: seen,
      onChanged: onChanged,
      icon: PhosphorIcons.eye,
      selectedIcon: PhosphorIcons.checkCircle,
      label: 'Hab gesehen',
      selectedLabel: 'Gesehen',
      iconOnly: iconOnly,
    );
  }
}
