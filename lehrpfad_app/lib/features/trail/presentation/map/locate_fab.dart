import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../location/user_position_provider.dart';
import '../../../nearby_trails/domain/karte_copy.dart';
import '../../../nearby_trails/presentation/bezug_aktionen.dart';

/// „Standort zentrieren“. Die Systemabfrage kommt nur nach diesem Tipp.
class LocateFab extends ConsumerWidget {
  const LocateFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(userPositionProvider).loading;
    return FloatingActionButton.small(
      heroTag: 'locate',
      tooltip: kt('a11y.zentrieren'),
      onPressed: loading
          ? null
          : () => BezugAktionen(ref).zentriereAufStandort(context),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
    );
  }
}
