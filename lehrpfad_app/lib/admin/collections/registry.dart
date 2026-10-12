import 'package:flutter/material.dart';

import '../core/collection_spec.dart';
import 'other_collections.dart';
import 'species_collections.dart';
import 'trails_collection.dart';

/// Alle Katalog-Ordner in Sidebar-Reihenfolge.
final adminCollections = <CollectionSpec>[
  trailsCollection,
  floraCollection,
  faunaCollection,
  geraeteCollection,
  merkmaleCollection,
  orteCollection,
  lebensraeumeCollection,
];

CollectionSpec? collectionById(String id) {
  for (final c in adminCollections) {
    if (c.id == id) return c;
  }
  return null;
}

/// Sidebar-Eintrag ohne Katalog-Tabelle.
class AdminSection {
  const AdminSection(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const moderationSection = AdminSection(
  'moderation',
  'Moderation',
  Icons.fact_check_outlined,
);
