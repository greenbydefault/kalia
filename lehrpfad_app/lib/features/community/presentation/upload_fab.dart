import 'package:flutter/material.dart';

import '../../trail/domain/trail.dart';
import 'image_upload_sheet.dart';

/// Foto-FAB auf der Übersichtskarte. [trail] aus der Peek-Card, sonst
/// oeffnet das Sheet den Trail-Picker.
class UploadFab extends StatelessWidget {
  const UploadFab({super.key, this.trail});

  final Trail? trail;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'upload',
      tooltip: 'Foto hochladen',
      onPressed: () => ImageUploadSheet.show(context, trail: trail),
      child: const Icon(Icons.add_a_photo_outlined),
    );
  }
}
