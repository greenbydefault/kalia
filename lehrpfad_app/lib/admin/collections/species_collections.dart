import 'package:flutter/material.dart';

import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import '../core/relation.dart';
import '../widgets/beziehungen_editor.dart';
import '../widgets/masse_editor.dart';
import '../widgets/species_media_block.dart';
import 'admin_catalogs.dart';

String _speciesRoute(RelationLink l) {
  final k = l.other['kategorie'] as String?;
  return '/${k == 'flora' || k == 'geraete' ? k : 'fauna'}/${Uri.encodeComponent(l.otherId)}';
}

String _fahrzeit(RelationLink l) {
  final sek = (l.extras['sek'] as num?)?.toInt();
  return sek == null ? '' : '${(sek / 60).round()} Min Auto';
}

const _poolExtras = [
  FieldSpec('rolle', 'Rolle', FieldKind.select, options: poolRolleOptions),
  FieldSpec(
    'sichtbarkeit',
    'Sichtbarkeit',
    FieldKind.select,
    options: poolSichtbarkeitOptions,
  ),
  FieldSpec('saison', 'Saison', FieldKind.select, options: poolSaisonOptions),
  FieldSpec('quelle', 'Quelle', FieldKind.text),
];

String? _poolLabel(RelationLink l) {
  final rolle = l.extras['rolle'] as String?;
  return rolle == null || rolle.isEmpty ? null : poolRolleOptions[rolle];
}

RelationSpec _trailsOfSpecies() => RelationSpec(
  backend: (c) => JoinTableBackend(
    c,
    table: 'trail_species',
    ownCol: 'species_id',
    otherCol: 'trail_id',
    otherTable: 'trails',
    otherTitleCol: 'name',
    otherSubtitleCol: 'region',
    extraCols: const ['nachweis'],
    orderCol: 'sortierung',
    orderScope: OrderScope.other,
    defaults: const {'nachweis': 'belegt'},
  ),
  routeFor: (l) => '/trails/${Uri.encodeComponent(l.otherId)}',
  extraFields: const [
    FieldSpec(
      'nachweis',
      'Nachweis',
      FieldKind.select,
      options: nachweisOptions,
    ),
  ],
  extraLabel: (l) => l.extras['nachweis'] == 'typisch' ? 'typisch' : null,
  emptyText: 'Auf keinem Trail verknüpft.',
  addLabel: 'Trail hinzufügen',
);

const _contentFields = <FieldSpec>[
  FieldSpec(
    'tiefe',
    'Tiefe',
    FieldKind.select,
    options: tiefeOptions,
    json: 'content',
    hint: 'kurz = Scan-Felder ohne Hörtext',
  ),
  FieldSpec(
    'hook',
    'Hook',
    FieldKind.longText,
    json: 'content',
    limit: FieldLimit(min: 12, max: 22, unit: LimitUnit.words),
    hint: 'Ein Satz, stärkster Satz zuerst',
  ),
  FieldSpec(
    'erkennung',
    'Erkennung',
    FieldKind.lines,
    json: 'content',
    hint: '2–4 Zeilen, je ≤ 12 Wörter',
    minLines: 3,
  ),
  FieldSpec(
    'lebensraum',
    'Lebensraum',
    FieldKind.longText,
    json: 'content',
    limit: FieldLimit(max: 40, unit: LimitUnit.words),
    hint: 'Lebensraum-Typ, kein Trailname',
  ),
  FieldSpec(
    'funFacts',
    'Fun Facts',
    FieldKind.lines,
    json: 'content',
    hint: '2–3 Zeilen',
    minLines: 3,
  ),
  FieldSpec(
    'hinweis',
    'Hinweis',
    FieldKind.text,
    json: 'content',
    limit: FieldLimit(max: 15, unit: LimitUnit.words),
    hint: 'Nur wenn relevant',
  ),
  FieldSpec(
    'hoertext',
    'Hörtext',
    FieldKind.longText,
    json: 'content',
    limit: FieldLimit(min: 90, max: 120, unit: LimitUnit.words),
    minLines: 9,
    hint: 'Einsprech-Skript, ohne Anrede (tools/ART_HOERTEXT.md)',
  ),
];

CollectionSpec _speciesCollection({
  required String id,
  required String label,
  required String singular,
  required IconData icon,
  required bool profile,
}) {
  return CollectionSpec(
    id: id,
    label: label,
    singular: singular,
    table: 'species',
    icon: icon,
    titleColumn: 'name_de',
    filterColumn: 'kategorie',
    filterValue: id,
    listColumns:
        'id,name_de,name_lat,kategorie,gruppe,kurztext,image_path,audio_path,'
        'hoertext:content->>hoertext,tiefe:content->>tiefe',
    subtitle: (r) {
      final lat = (r['name_lat'] as String?) ?? '';
      if (lat.isNotEmpty) return lat;
      return gruppeOptions[r['gruppe']];
    },
    listFilters: profile
        ? [ListFilterSpec('gruppe', 'Gruppe', gruppeOptions)]
        : [],
    gaps: (r) => [
      if (((r['kurztext'] as String?) ?? '').trim().isEmpty) 'Kurztext fehlt',
      if (r['tiefe'] != 'kurz' &&
          ((r['hoertext'] as String?) ?? '').trim().isEmpty)
        'Hörtext fehlt',
    ],
    dependents: const [
      DependentSpec('trail_species', 'species_id', 'Trails'),
      DependentSpec('pool_arten', 'species_id', 'Pool-Einträge'),
      DependentSpec(
        'species_beziehungen',
        'to_species_id',
        'Beziehungen anderer Arten',
      ),
      DependentSpec('species_sightings', 'species_id', 'Gesehen-Markierungen'),
    ],
    newRow: (rid, title) => {
      'id': rid,
      'name_de': title,
      'kategorie': id,
      'content': profile ? {'tiefe': 'kurz'} : <String, dynamic>{},
      if (!profile) 'icon_key': 'geraet',
    },
    blocks: [
      FieldsBlock('Grunddaten', [
        const FieldSpec('name_de', 'Name', FieldKind.text, required: true),
        if (profile)
          const FieldSpec('name_lat', 'Lateinischer Name', FieldKind.text),
        const FieldSpec(
          'kurztext',
          'Kurztext',
          FieldKind.longText,
          hint: 'Fallback-Hook für alte Caches',
        ),
        const FieldSpec(
          'aliases',
          'Aliase',
          FieldKind.tags,
          hint: 'Namen, mit denen Trails diese Art auflösen',
        ),
        if (profile) ...[
          FieldSpec(
            'gruppe',
            'Artgruppe',
            FieldKind.select,
            options: gruppeOptions,
          ),
          FieldSpec(
            'seltenheit',
            'Seltenheit',
            FieldKind.select,
            options: seltenheitOptions,
          ),
          const FieldSpec(
            'gefahr',
            'Gefahr (1–5)',
            FieldKind.integer,
            hint: '1 sehr gering … 5 nicht annähern, 0 = offen',
          ),
        ] else
          FieldSpec(
            'icon_key',
            'Icon',
            FieldKind.select,
            options: geraeteIconOptions,
          ),
      ]),
      const FieldsBlock(
        'Steckbrief',
        _contentFields,
        description:
            'Vorgaben aus tools/SPECIES_CONTENT.md und GERAETE_CONTENT.md, nur als Warnung.',
      ),
      if (profile)
        FieldsBlock('Profil', [
          const FieldSpec('nahrung', 'Nahrung', FieldKind.tags),
          const FieldSpec('tax_reich', 'Reich', FieldKind.text),
          const FieldSpec('tax_stamm', 'Stamm', FieldKind.text),
          const FieldSpec('tax_klasse', 'Klasse', FieldKind.text),
          const FieldSpec('tax_ordnung', 'Ordnung', FieldKind.text),
          const FieldSpec('tax_familie', 'Familie', FieldKind.text),
        ]),
      if (profile) CustomBlock('Maße', (context, ctx) => MasseEditor(ctx: ctx)),
      if (profile)
        RelationBlock(
          'Merkmale',
          RelationSpec(
            backend: (c) => JoinTableBackend(
              c,
              table: 'species_merkmale',
              ownCol: 'species_id',
              otherCol: 'merkmal_id',
              otherTable: 'merkmale',
              otherTitleCol: 'name_de',
              otherSubtitleCol: 'gruppe',
            ),
            routeFor: (l) => '/merkmale/${Uri.encodeComponent(l.otherId)}',
            emptyText: 'Keine Merkmale.',
            limitHint: '4–8 Merkmale, nur was stimmt',
          ),
        ),
      if (profile)
        CustomBlock(
          'Beziehungen',
          (context, ctx) => BeziehungenEditor(ctx: ctx),
        ),
      RelationBlock('Kommt vor auf', _trailsOfSpecies()),
      if (profile)
        RelationBlock(
          'Lebensräume im Pool',
          RelationSpec(
            backend: (c) => JoinTableBackend(
              c,
              table: 'pool_arten',
              ownCol: 'species_id',
              otherCol: 'lebensraum',
              otherTable: 'lebensraeume',
              otherTitleCol: 'name_de',
              extraCols: const ['rolle', 'sichtbarkeit', 'saison', 'quelle'],
            ),
            routeFor: (l) => '/lebensraeume/${Uri.encodeComponent(l.otherId)}',
            extraFields: _poolExtras,
            extraLabel: _poolLabel,
            emptyText: 'In keinem Pool.',
          ),
          description: 'Wo Familien die Art „typisch“ antreffen können.',
        ),
      if (profile)
        RelationBlock(
          'Wird erwähnt von',
          RelationSpec(
            backend: (c) => JoinTableBackend(
              c,
              table: 'species_beziehungen',
              ownCol: 'to_species_id',
              otherCol: 'from_id',
              otherTable: 'species',
              otherTitleCol: 'name_de',
              otherSubtitleCol: 'kategorie',
              extraCols: const ['typ'],
              editable: false,
            ),
            routeFor: _speciesRoute,
            extraLabel: (l) => beziehungTypOptions[l.extras['typ']],
            emptyText: 'Von keiner Art als Beziehung genannt.',
          ),
          description:
              'Rückverweise aus den Beziehungen anderer Arten. Nur Anzeige.',
        ),
      CustomBlock(
        'Medien',
        (context, ctx) => SpeciesMediaBlock(ctx: ctx),
        description: 'Bild und Hörtext-Audio.',
      ),
    ],
  );
}

final floraCollection = _speciesCollection(
  id: 'flora',
  label: 'Flora',
  singular: 'Pflanze',
  icon: Icons.local_florist_outlined,
  profile: true,
);

final faunaCollection = _speciesCollection(
  id: 'fauna',
  label: 'Fauna',
  singular: 'Tier',
  icon: Icons.pets_outlined,
  profile: true,
);

final geraeteCollection = _speciesCollection(
  id: 'geraete',
  label: 'Geräte',
  singular: 'Gerät',
  icon: Icons.sports_handball_outlined,
  profile: false,
);

/// Für Relationen anderer Collections (Orte, Lebensräume, Merkmale).
String speciesRouteFor(RelationLink l) => _speciesRoute(l);
String fahrzeitLabel(RelationLink l) => _fahrzeit(l);
