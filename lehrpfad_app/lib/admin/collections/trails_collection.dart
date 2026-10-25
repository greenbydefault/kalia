import 'package:flutter/material.dart';

import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import '../core/relation.dart';
import '../widgets/child_rows_editor.dart';
import '../widgets/trail_hero_gallery.dart';
import 'admin_catalogs.dart';

final _editorialTags = {
  for (final e in tagOptions.entries)
    if (e.key != 'parkplatz-nahe' && e.key != 'wc-am-weg') e.key: e.value,
};

String _speciesRoute(RelationLink l) {
  final k = l.other['kategorie'] as String?;
  return '/${k == 'flora' || k == 'geraete' ? k : 'fauna'}/${Uri.encodeComponent(l.otherId)}';
}

String _fahrzeit(RelationLink l) {
  final sek = (l.extras['sek'] as num?)?.toInt();
  return sek == null ? '' : '${(sek / 60).round()} Min Auto';
}

/// Relation Trail → Arten (`trail_species`, mit Nachweis-Stufe).
final trailArtenRelation = RelationSpec(
  backend: (c) => JoinTableBackend(
    c,
    table: 'trail_species',
    ownCol: 'trail_id',
    otherCol: 'species_id',
    otherTable: 'species',
    otherTitleCol: 'name_de',
    otherSubtitleCol: 'kategorie',
    extraCols: const ['nachweis', 'sortierung'],
    orderCol: 'sortierung',
    defaults: const {'nachweis': 'belegt'},
  ),
  routeFor: _speciesRoute,
  extraFields: const [
    FieldSpec(
      'nachweis',
      'Nachweis',
      FieldKind.select,
      options: nachweisOptions,
    ),
  ],
  extraLabel: (l) => l.extras['nachweis'] == 'typisch' ? 'typisch' : null,
  createKinds: const ['flora', 'fauna'],
  emptyText: 'Keine Arten verknüpft.',
);

final trailsCollection = CollectionSpec(
  id: 'trails',
  label: 'Trails',
  singular: 'Trail',
  table: 'trails',
  icon: Icons.route_outlined,
  titleColumn: 'name',
  listColumns: 'id,name,typ,region,kurzbeschreibung,beschreibung,sichtbar',
  importPath: '/import',
  subtitle: (r) {
    final typ = typOptions[r['typ']] ?? r['typ'];
    final region = (r['region'] as String?) ?? '';
    return region.isEmpty ? '$typ' : '$typ · $region';
  },
  listFilters: [ListFilterSpec('typ', 'Typ', typOptions)],
  gaps: (r) => [
    if (r['sichtbar'] == false) 'Unsichtbar (Entwurf)',
    if (((r['kurzbeschreibung'] as String?) ?? '').trim().isEmpty)
      'Kurzbeschreibung fehlt',
    if (((r['beschreibung'] as String?) ?? '').trim().isEmpty)
      'Beschreibung fehlt',
  ],
  // Geometrie (route/area/Stationen-Koordinaten) kommt aus der OSM-Pipeline.
  canCreate: false,
  confirmDeleteByTyping: true,
  dependents: const [
    DependentSpec('stations', 'trail_id', 'Stationen'),
    DependentSpec('amenities', 'trail_id', 'Amenities'),
    DependentSpec('images', 'trail_id', 'Bilder'),
    DependentSpec('trail_species', 'trail_id', 'Arten-Zuordnungen'),
    DependentSpec('trail_pois', 'trail_id', 'Orte-Zuordnungen'),
    DependentSpec('comments', 'trail_id', 'Kommentare'),
    DependentSpec('ratings', 'trail_id', 'Bewertungen'),
    DependentSpec('trail_bookmarks', 'trail_id', 'Merklisten-Einträge'),
    DependentSpec('trail_completions', 'trail_id', 'Gelaufen-Markierungen'),
  ],
  manualCascade: const [DependentSpec('trail_pois', 'trail_id', 'Orte')],
  newRow: (id, title) => {'id': id, 'name': title, 'typ': 'wald', 'route': []},
  blocks: [
    FieldsBlock('Grunddaten', [
      const FieldSpec('name', 'Name', FieldKind.text, required: true),
      FieldSpec(
        'typ',
        'Typ',
        FieldKind.select,
        options: typOptions,
        required: true,
      ),
      const FieldSpec(
        'form',
        'Form',
        FieldKind.select,
        options: formOptions,
        required: true,
      ),
      const FieldSpec(
        'land',
        'Land',
        FieldKind.select,
        options: {'DE': 'Deutschland', 'DK': 'Dänemark', 'ES': 'Spanien'},
        nullable: true,
      ),
      const FieldSpec('bundesland', 'Bundesland / Region', FieldKind.text, nullable: true),
      const FieldSpec('kreis', 'Kreis', FieldKind.text, nullable: true),
      const FieldSpec('ort', 'Ort', FieldKind.text, nullable: true),
      const FieldSpec('schutzgebiet', 'Schutzgebiet', FieldKind.text, nullable: true),
      const FieldSpec('region', 'Region', FieldKind.text),
      const FieldSpec('betreiber', 'Betreiber', FieldKind.text),
      const FieldSpec('markierung', 'Markierung', FieldKind.text),
      const FieldSpec('start_name', 'Startpunkt', FieldKind.text),
      const FieldSpec('start_lat', 'Start Breite', FieldKind.number, nullable: true),
      const FieldSpec('start_lon', 'Start Länge', FieldKind.number, nullable: true),
      const FieldSpec('anreise', 'Anreise', FieldKind.longText),
    ]),
    FieldsBlock('Texte', [
      const FieldSpec(
        'kurzbeschreibung',
        'Kurzbeschreibung',
        FieldKind.longText,
        limit: FieldLimit(max: 180),
        hint: 'Card-Teaser, keine Anrede',
      ),
      const FieldSpec(
        'beschreibung',
        'Beschreibung',
        FieldKind.longText,
        limit: FieldLimit(min: 400, max: 650),
        minLines: 7,
        hint: 'Satz 1 trägt allein',
      ),
      const FieldSpec(
        'hoertext',
        'Hörtext',
        FieldKind.longText,
        limit: FieldLimit(min: 70, max: 110, unit: LimitUnit.words),
        nullable: true,
        minLines: 5,
        hint: 'Einsprech-Skript, keine Anrede',
      ),
    ], description: 'Vorgaben aus tools/TRAIL_SCAN.md, nur als Warnung.'),
    const FieldsBlock('Kennzahlen', [
      FieldSpec(
        'laenge_km',
        'Länge (km)',
        FieldKind.number,
        hint: 'bei Fläche 0',
      ),
      FieldSpec('dauer_min', 'Dauer (Min)', FieldKind.integer),
      FieldSpec('rundkurs', 'Rundkurs', FieldKind.boolean),
    ]),
    const FieldsBlock('Besuch', [
      FieldSpec('website', 'Website', FieldKind.text, nullable: true),
      FieldSpec('eintritt', 'Eintritt', FieldKind.boolean),
      FieldSpec(
        'eintritt_preise',
        'Eintrittspreise',
        FieldKind.text,
        nullable: true,
      ),
      FieldSpec(
        'oeffnungszeiten',
        'Öffnungszeiten',
        FieldKind.longText,
        nullable: true,
      ),
      FieldSpec(
        'besuchshinweise',
        'Besuchshinweise',
        FieldKind.longText,
        limit: FieldLimit(max: 280),
        nullable: true,
        hint: 'Nur was kein Tag zeigt',
      ),
    ]),
    FieldsBlock('Einordnung', [
      const FieldSpec(
        'naturraum',
        'Naturraum',
        FieldKind.select,
        options: naturraumOptions,
      ),
      FieldSpec('tags', 'Tags', FieldKind.multiSelect, options: _editorialTags),
    ]),
    RelationBlock(
      'Lebensräume',
      RelationSpec(
        backend: (c) => ArrayForwardBackend(
          c,
          ownTable: 'trails',
          arrayCol: 'lebensraeume',
          otherTable: 'lebensraeume',
          otherTitleCol: 'name_de',
          maxItems: 3,
        ),
        routeFor: (l) => '/lebensraeume/${Uri.encodeComponent(l.otherId)}',
        emptyText: 'Kein Lebensraum (Spielplatz, Geopfad).',
        limitHint: 'Maximal 3',
      ),
      description: 'Bestimmt den Arten-Pool für „typische“ Arten.',
    ),
    RelationBlock('Arten', trailArtenRelation),
    RelationBlock(
      'Orte in der Nähe',
      RelationSpec(
        backend: (c) => JoinTableBackend(
          c,
          table: 'trail_pois',
          ownCol: 'trail_id',
          otherCol: 'poi_id',
          otherTable: 'pois',
          otherTitleCol: 'name',
          otherSubtitleCol: 'kategorie',
          extraCols: const ['sek'],
          sortByExtra: 'sek',
          editable: false,
        ),
        routeFor: (l) => '/orte/${Uri.encodeComponent(l.otherId)}',
        extraLabel: _fahrzeit,
        emptyText: 'Kein Ort innerhalb 20 Min.',
      ),
      description:
          'Fahrzeit-Zuordnung, berechnet von tools/nearby_zeiten.py. Nur Anzeige.',
    ),
    CustomBlock(
      'Bilder',
      (context, ctx) => TrailHeroGallery(ctx: ctx),
      description: 'Hero-Fotos des Trails (Reihenfolge = Slider).',
    ),
    CustomBlock(
      'Stationen',
      (context, ctx) => ChildRowsEditor(
        ctx: ctx,
        table: 'stations',
        fkColumn: 'trail_id',
        orderColumn: 'reihenfolge',
        title: (r) => '${r['reihenfolge']}. ${r['titel']}',
        info: (r) => 'km ${r['km']} · ${r['lat']}, ${r['lon']}',
        fields: [
          const FieldSpec('titel', 'Titel', FieldKind.text, required: true),
          const FieldSpec('thema', 'Thema', FieldKind.text),
          const FieldSpec(
            'kurztext',
            'Kurztext',
            FieldKind.longText,
            minLines: 4,
          ),
          FieldSpec(
            'erlebnisse',
            'Erlebnisse',
            FieldKind.multiSelect,
            options: erlebnisOptions,
          ),
          const FieldSpec('barrierefrei', 'Barrierefrei', FieldKind.boolean),
        ],
        emptyText: 'Keine Stationen.',
      ),
      description:
          'Texte editierbar, Koordinaten und Reihenfolge kommen aus der Pipeline.',
    ),
    CustomBlock(
      'Amenities am Weg',
      (context, ctx) => ChildRowsEditor(
        ctx: ctx,
        table: 'amenities',
        fkColumn: 'trail_id',
        orderColumn: 'id',
        title: (r) {
          final k = amenityOptions[r['kategorie']] ?? '${r['kategorie']}';
          final n = (r['name'] as String?) ?? '';
          return n.isEmpty ? k : '$k · $n';
        },
        info: (r) => '${r['lat']}, ${r['lon']}',
        fields: [
          FieldSpec(
            'kategorie',
            'Kategorie',
            FieldKind.select,
            options: amenityOptions,
          ),
          const FieldSpec('name', 'Name', FieldKind.text, nullable: true),
        ],
        canDelete: true,
        emptyText: 'Keine Amenities.',
      ),
    ),
  ],
);
