import 'package:flutter/material.dart';

/// Gemeinsamer Abschnittstitel für Steckbrief und Profil.
class SpeciesSectionTitle extends StatelessWidget {
  const SpeciesSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }
}
