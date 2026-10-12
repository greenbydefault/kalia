import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import '../core/relation.dart';
import 'admin_catalogs.dart';
import 'species_collections.dart';

RelationSpec _speciesRelation({
  required JoinTableBackend Function(SupabaseClient client) backend,
  List<FieldSpec> extraFields = const [],
  String? Function(RelationLink)? extraLabel,
  String emptyText = 'Keine Arten verknüpft.',
}) => RelationSpec(
  backend: (c) => backend(c),
  routeFor: speciesRouteFor,
  extraFields: extraFields,
  extraLabel: extraLabel,
  createKinds: const ['flora', 'fauna'],
  emptyText: emptyText,
  addLabel: 'Art hinzufügen',
);

final merkmaleCollection = CollectionSpec(
  id: 'merkmale',
  label: 'Merkmale',
  singular: 'Merkmal',
  table: 'merkmale',
  icon: Icons.sell_outlined,
  titleColumn: 'name_de',
  listColumns: 'id,name_de,beschreibung,gruppe,sortierung',
  subtitle: (r) => merkmalGruppeOptions[r['gruppe']],
  listFilters: const [ListFilterSpec('gruppe', 'Gruppe', merkmalGruppeOptions)],
  gaps: (r) => [
    if (((r['beschreibung'] as String?) ?? '').trim().isEmpty)
      'Beschreibung fehlt',
  ],
  dependents: const [DependentSpec('species_merkmale', 'merkmal_id', 'Arten')],
  newRow: (id, title) => {'id': id, 'name_de': title, 'gruppe': 'aussehen'},
  blocks: [
    FieldsBlock('Merkmal', [
      const FieldSpec('name_de', 'Name', FieldKind.text, required: true),
      const FieldSpec(
        'beschreibung',
        'Beschreibung',
        FieldKind.longText,
        hint: '1 Satz, für Kinder, kein Lexikon',
      ),
      const FieldSpec(
        'gruppe',
        'Gruppe',
        FieldKind.select,
        options: merkmalGruppeOptions,
      ),
      FieldSpec(
        'icon_key',
        'Icon',
        FieldKind.select,
        options: merkmaleIconOptions,
      ),
      const FieldSpec('sortierung', 'Sortierung', FieldKind.integer),
    ]),
    RelationBlock(
      'Arten',
      _speciesRelation(
        backend: (c) => JoinTableBackend(
          c,
          table: 'species_merkmale',
          ownCol: 'merkmal_id',
          otherCol: 'species_id',
          otherTable: 'species',
          otherTitleCol: 'name_de',
          otherSubtitleCol: 'kategorie',
        ),
      ),
      description: 'Alle Arten, die dieses Merkmal tragen.',
    ),
  ],
);

final orteCollection = CollectionSpec(
  id: 'orte',
  label: 'Orte in der Nähe',
  singular: 'Ort',
  table: 'pois',
  icon: Icons.place_outlined,
  titleColumn: 'name',
  listColumns: 'id,name,kategorie,kurztext',
  subtitle: (r) => poiKategorieOptions[r['kategorie']],
  listFilters: [ListFilterSpec('kategorie', 'Kategorie', poiKategorieOptions)],
  gaps: (r) => [
    if (((r['kurztext'] as String?) ?? '').trim().isEmpty) 'Kurztext fehlt',
  ],
  dependents: const [
    DependentSpec('trail_pois', 'poi_id', 'Trail-Zuordnungen'),
  ],
  // Koordinaten und Fahrzeiten gehören zur Pipeline (seed_pois.py,
  // nearby_zeiten.py); neuer Ort braucht lat/lon.
  newRow: (id, title) => {
    'id': id,
    'name': title,
    'kategorie': 'cafe',
    'lat': 0,
    'lon': 0,
  },
  blocks: [
    FieldsBlock('Ort', [
      const FieldSpec('name', 'Name', FieldKind.text, required: true),
      FieldSpec(
        'kategorie',
        'Kategorie',
        FieldKind.select,
        options: poiKategorieOptions,
      ),
      const FieldSpec(
        'kurztext',
        'Kurztext',
        FieldKind.longText,
        hint: '1 Satz, Familien-Nutzen',
      ),
      const FieldSpec('website', 'Website', FieldKind.text, nullable: true),
      const FieldSpec('telefon', 'Telefon', FieldKind.text, nullable: true),
      const FieldSpec(
        'oeffnungszeiten',
        'Öffnungszeiten (Anzeige)',
        FieldKind.text,
        nullable: true,
      ),
      const FieldSpec(
        'opening_hours',
        'opening_hours (OSM)',
        FieldKind.text,
        nullable: true,
        hint: 'Für das „Jetzt geöffnet“-Badge',
      ),
    ]),
    const FieldsBlock(
      'Lage',
      [
        FieldSpec('lat', 'Breitengrad', FieldKind.number),
        FieldSpec('lon', 'Längengrad', FieldKind.number),
      ],
      description:
          'Ändert die Fahrzeiten: danach tools/nearby_zeiten.py --all.',
    ),
    RelationBlock(
      'Trails in 20 Min',
      RelationSpec(
        backend: (c) => JoinTableBackend(
          c,
          table: 'trail_pois',
          ownCol: 'poi_id',
          otherCol: 'trail_id',
          otherTable: 'trails',
          otherTitleCol: 'name',
          otherSubtitleCol: 'region',
          extraCols: const ['sek'],
          sortByExtra: 'sek',
          editable: false,
        ),
        routeFor: (l) => '/trails/${Uri.encodeComponent(l.otherId)}',
        extraLabel: fahrzeitLabel,
        emptyText: 'Von keinem Trail in 20 Min erreichbar.',
      ),
      description: 'Berechnete Zuordnung, nur Anzeige.',
    ),
  ],
);

final lebensraeumeCollection = CollectionSpec(
  id: 'lebensraeume',
  label: 'Lebensräume',
  singular: 'Lebensraum',
  table: 'lebensraeume',
  icon: Icons.landscape_outlined,
  titleColumn: 'name_de',
  listColumns: 'id,name_de,sortierung',
  dependents: const [
    DependentSpec('pool_arten', 'lebensraum', 'Pool-Arten'),
    DependentSpec('pool_naturraeume', 'lebensraum', 'Naturräume'),
  ],
  newRow: (id, title) => {'id': id, 'name_de': title},
  blocks: [
    const FieldsBlock('Lebensraum', [
      FieldSpec('name_de', 'Name', FieldKind.text, required: true),
      FieldSpec('sortierung', 'Sortierung', FieldKind.integer),
    ]),
    RelationBlock(
      'Arten im Pool',
      _speciesRelation(
        backend: (c) => JoinTableBackend(
          c,
          table: 'pool_arten',
          ownCol: 'lebensraum',
          otherCol: 'species_id',
          otherTable: 'species',
          otherTitleCol: 'name_de',
          otherSubtitleCol: 'kategorie',
          extraCols: const ['rolle', 'sichtbarkeit', 'saison', 'quelle'],
        ),
        extraFields: const [
          FieldSpec(
            'rolle',
            'Rolle',
            FieldKind.select,
            options: poolRolleOptions,
          ),
          FieldSpec(
            'sichtbarkeit',
            'Sichtbarkeit',
            FieldKind.select,
            options: poolSichtbarkeitOptions,
          ),
          FieldSpec(
            'saison',
            'Saison',
            FieldKind.select,
            options: poolSaisonOptions,
          ),
          FieldSpec('quelle', 'Quelle', FieldKind.text),
        ],
        extraLabel: (l) {
          final r = l.extras['rolle'] as String?;
          return r == null || r.isEmpty ? null : poolRolleOptions[r];
        },
        emptyText: 'Noch keine Arten im Pool.',
      ),
      description:
          'Arten, die Familien in diesem Lebensraum typisch antreffen. Basis für „typisch“ am Trail.',
    ),
    RelationBlock(
      'Naturräume',
      RelationSpec(
        backend: (c) => JoinTableBackend(
          c,
          table: 'pool_naturraeume',
          ownCol: 'lebensraum',
          otherCol: 'naturraum',
          staticOptions: naturraumOptions,
        ),
        routeFor: (_) => '',
        emptyText: 'In keinem Naturraum.',
        addLabel: 'Naturraum hinzufügen',
      ),
      description: 'In welchen Naturräumen der Pool gilt.',
    ),
    RelationBlock(
      'Trails',
      RelationSpec(
        backend: (c) => ArrayReverseBackend(
          c,
          otherTable: 'trails',
          arrayCol: 'lebensraeume',
          otherTitleCol: 'name',
          otherSubtitleCol: 'region',
          maxItems: 3,
        ),
        routeFor: (l) => '/trails/${Uri.encodeComponent(l.otherId)}',
        emptyText: 'Kein Trail in diesem Lebensraum.',
        addLabel: 'Trail hinzufügen',
      ),
    ),
  ],
);
