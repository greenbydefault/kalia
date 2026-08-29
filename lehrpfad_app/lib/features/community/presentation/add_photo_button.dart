import 'package:flutter/material.dart';

import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import 'image_upload_sheet.dart';

/// „Foto hinzufügen"-Button. Nur sichtbar, wenn Supabase angebunden ist.
/// [station] vorausgewaehlt, wenn der Button aus einer StationCard kommt.
class AddPhotoButton extends StatelessWidget {
  final Trail trail;
  final Station? station;
  final bool iconOnly;

  const AddPhotoButton({
    super.key,
    required this.trail,
    this.station,
    this.iconOnly = false,
  });

  void _onPressed(BuildContext context) {
    ImageUploadSheet.show(context, trail: trail, initialStation: station);
  }

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return IconButton(
        icon: const Icon(Icons.add_a_photo_outlined, size: 20),
        tooltip: 'Foto zu dieser Station hinzufügen',
        visualDensity: VisualDensity.compact,
        onPressed: () => _onPressed(context),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _onPressed(context),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text('Foto hinzufügen'),
    );
  }
}
