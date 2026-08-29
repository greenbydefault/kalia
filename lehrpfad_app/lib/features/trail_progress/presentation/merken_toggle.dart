import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/widgets/status_toggle.dart';

/// Toggle „Merken“.
class MerkenToggle extends StatelessWidget {
  const MerkenToggle({
    super.key,
    required this.bookmarked,
    required this.onChanged,
    this.iconOnly = false,
  });

  final bool bookmarked;
  final ValueChanged<bool> onChanged;

  /// Kompakt ohne Label — für enge Peek-CTA-Zeilen.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return StatusToggle(
      selected: bookmarked,
      onChanged: onChanged,
      icon: PhosphorIcons.bookmarkSimple,
      selectedIcon: PhosphorIconsFill.bookmarkSimple,
      label: 'Merken',
      selectedLabel: 'Gemerkte',
      iconOnly: iconOnly,
    );
  }
}
