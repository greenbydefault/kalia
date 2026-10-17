import 'package:flutter/material.dart';

import '../nearby_trails/domain/karte_copy.dart';

/// Platzhalter für den Tab „Erkunden“. Inhalt folgt (Spec: noch offen).
class ErkundenScreen extends StatelessWidget {
  const ErkundenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            kt('nav.erkunden'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
