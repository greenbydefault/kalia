import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import 'image_upload_sheet.dart';

/// „Foto hinzufügen"-Button. Nur sichtbar, wenn Supabase angebunden ist;
/// ohne Login verweist ein SnackBar auf die Anmeldung.
/// [station] vorausgewaehlt, wenn der Button aus einer StationCard kommt.
class AddPhotoButton extends ConsumerWidget {
  final Trail trail;
  final Station? station;
  final bool iconOnly;

  const AddPhotoButton({
    super.key,
    required this.trail,
    this.station,
    this.iconOnly = false,
  });

  void _onPressed(BuildContext context, bool loggedIn) {
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Melde dich an, um Fotos hochzuladen.'),
        ),
      );
      return;
    }
    ImageUploadSheet.show(context, trail, initialStation: station);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authStateProvider).value != null;
    if (iconOnly) {
      return IconButton(
        icon: const Icon(Icons.add_a_photo_outlined, size: 20),
        tooltip: 'Foto zu dieser Station hinzufügen',
        visualDensity: VisualDensity.compact,
        onPressed: () => _onPressed(context, loggedIn),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _onPressed(context, loggedIn),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text('Foto hinzufügen'),
    );
  }
}
