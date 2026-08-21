import 'package:flutter/material.dart';

/// Kompakter Fakten-Chip (Icon + Label) im Kopfbereich des Trail-Sheets.
class FactChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const FactChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
      visualDensity: VisualDensity.compact,
    );
  }
}
