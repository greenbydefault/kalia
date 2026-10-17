import 'dart:convert';

import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../trail/data/providers.dart';
import '../../trail/domain/gebiet.dart';
import '../../trail/domain/trail.dart';
import '../domain/bezugspunkt.dart';
import '../domain/eintrag.dart';
import '../domain/eintrag_mapper.dart';
import '../domain/karte_logik.dart';
import 'bezug_provider.dart';

const _filterKey = 'karte_filter';

// ---------------------------------------------------------------------------
// Sheet, Gebiet, Modus, Sortierung
// ---------------------------------------------------------------------------

enum SheetHoehe { eingeklappt, halb, ganz }

enum ListenModus { vorschlaege, alle }

/// Nach dem Onboarding und beim Öffnen des Tabs: halb.
final sheetHoeheProvider = NotifierProvider<SheetHoeheNotifier, SheetHoehe>(
  SheetHoeheNotifier.new,
);

class SheetHoeheNotifier extends Notifier<SheetHoehe> {
  @override
  SheetHoehe build() => SheetHoehe.halb;

  /// Zurück zu „Vorschläge“, sobald Gebiet „Alle“ gilt und das Sheet auf
  /// halb oder eingeklappt geht.
  void set(SheetHoehe hoehe) {
    state = hoehe;
    if (hoehe != SheetHoehe.ganz && ref.read(gebietProvider) == null) {
      ref.read(alleAngefordertProvider.notifier).set(false);
    }
  }
}

/// Einfachauswahl. `null` = „Alle“.
final gebietProvider = NotifierProvider<GebietNotifier, Gebiet?>(
  GebietNotifier.new,
);

class GebietNotifier extends Notifier<Gebiet?> {
  @override
  Gebiet? build() => null;

  /// Das gewählte Gebiet erneut tippen setzt auf „Alle“ zurück.
  void toggle(Gebiet gebiet) => set(state == gebiet ? null : gebiet);

  void set(Gebiet? gebiet) {
    state = gebiet;
    if (gebiet == null && ref.read(sheetHoeheProvider) != SheetHoehe.ganz) {
      ref.read(alleAngefordertProvider.notifier).set(false);
    }
  }
}

/// „Alle anzeigen“ wurde getippt (Modus „Alle“ ohne Gebiet).
final alleAngefordertProvider = NotifierProvider<AlleAngefordertNotifier, bool>(
  AlleAngefordertNotifier.new,
);

class AlleAngefordertNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// „Alle“ nach „Alle anzeigen“ oder sobald ein Gebiet gewählt ist.
final listenModusProvider = Provider<ListenModus>((ref) {
  final gebiet = ref.watch(gebietProvider);
  final alle = ref.watch(alleAngefordertProvider);
  return gebiet != null || alle ? ListenModus.alle : ListenModus.vorschlaege;
});

final sortierungProvider = NotifierProvider<SortierungNotifier, Sortierung>(
  SortierungNotifier.new,
);

class SortierungNotifier extends Notifier<Sortierung> {
  @override
  Sortierung build() => Sortierung.anfahrt;

  void set(Sortierung s) => state = s;
}

/// Tipp auf „Alle anzeigen“: halb → ganz, Modus „Alle“.
void zeigeAlle(WidgetRef ref) {
  ref.read(alleAngefordertProvider.notifier).set(true);
  ref.read(sheetHoeheProvider.notifier).set(SheetHoehe.ganz);
}

// ---------------------------------------------------------------------------
// Filter (übernommen, persistiert)
// ---------------------------------------------------------------------------

final karteFilterProvider = NotifierProvider<KarteFilterNotifier, KarteFilter>(
  KarteFilterNotifier.new,
);

class KarteFilterNotifier extends Notifier<KarteFilter> {
  @override
  KarteFilter build() {
    _load();
    return KarteFilter.standard;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_filterKey);
      if (raw == null) return;
      final f = filterVonJson(jsonDecode(raw));
      if (f != state) state = f;
    } catch (_) {}
  }

  Future<void> uebernehmen(KarteFilter filter) async {
    state = filter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filterKey, jsonEncode(filterZuJson(filter)));
  }
}

Map<String, Object?> filterZuJson(KarteFilter f) => {
  'arten': [for (final a in f.arten) a.name],
  'dauer': f.dauer?.name,
  'laenge': f.laenge?.name,
  'merkmale': [for (final m in f.merkmale) m.name],
};

KarteFilter filterVonJson(Object? raw) {
  if (raw is! Map) return KarteFilter.standard;
  T? byName<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  final arten = <EintragArt>{
    for (final n in (raw['arten'] as List? ?? const []))
      ?byName(EintragArt.values, n),
  };
  return KarteFilter(
    arten: arten.isEmpty ? KarteFilter.standard.arten : arten,
    dauer: byName(DauerBereich.values, raw['dauer']),
    laenge: byName(LaengeBereich.values, raw['laenge']),
    merkmale: {
      for (final n in (raw['merkmale'] as List? ?? const []))
        ?byName(Merkmal.values, n),
    },
  );
}

// ---------------------------------------------------------------------------
// Einträge, Menge M, Anzeige
// ---------------------------------------------------------------------------

/// Alle Einträge des Katalogs. `null`, solange die Trails laden.
final eintraegeProvider = Provider<List<Eintrag>?>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value;
  if (trails == null) return null;
  return [for (final t in trails) ?eintragVon(t)];
});

/// Menge M: Umkreis, Gebiet und Filter erfüllt. Liste und Marker zeigen
/// immer genau diese Menge.
final mengeProvider = Provider<List<Treffer>?>((ref) {
  final alle = ref.watch(eintraegeProvider);
  if (alle == null) return null;
  return berechneMenge(
    alle,
    bezug: ref.watch(aktuellerBezugProvider)?.coords,
    umkreis: ref.watch(umkreisProvider),
    gebiet: ref.watch(gebietProvider),
    filter: ref.watch(karteFilterProvider),
  );
});

/// Was das Sheet zeigt.
class KarteAnzeige {
  const KarteAnzeige({
    required this.modus,
    required this.menge,
    required this.sichtbar,
    this.leer,
  });

  final ListenModus modus;

  /// Ganze Menge M, nach Anfahrt sortiert.
  final List<Treffer> menge;

  /// Vorschläge (höchstens 4) oder die sortierte Menge M.
  final List<Treffer> sichtbar;

  /// Gesetzt, wenn M leer ist: E5, E6 oder E7.
  final LeerFall? leer;

  int get n => menge.length;
}

final karteAnzeigeProvider = Provider<KarteAnzeige?>((ref) {
  final menge = ref.watch(mengeProvider);
  final alle = ref.watch(eintraegeProvider);
  if (menge == null || alle == null) return null;
  final modus = ref.watch(listenModusProvider);
  final sortierung = ref.watch(sortierungProvider);
  final nachAnfahrt = sortiere(menge, Sortierung.anfahrt);
  if (menge.isEmpty) {
    return KarteAnzeige(
      modus: modus,
      menge: const [],
      sichtbar: const [],
      leer: bestimmeLeerFall(
        alle,
        bezug: ref.watch(aktuellerBezugProvider)?.coords,
        umkreis: ref.watch(umkreisProvider),
        gebiet: ref.watch(gebietProvider),
        filter: ref.watch(karteFilterProvider),
      ),
    );
  }
  final sichtbar = modus == ListenModus.alle
      ? sortiere(menge, sortierung)
      : vorschlaege(menge, DateTime.now());
  return KarteAnzeige(modus: modus, menge: nachAnfahrt, sichtbar: sichtbar);
});

/// Zähler: jeder Zuwachs ist ein Signal ohne Nutzlast.
class SignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

/// Filter übernommen: Liste springt nach oben.
final listeNachObenProvider = NotifierProvider<SignalNotifier, int>(
  SignalNotifier.new,
);

/// Ein Eintrag wurde ausgewählt und soll direkt das Detail öffnen.
final detailAnfrageProvider = NotifierProvider<SignalNotifier, int>(
  SignalNotifier.new,
);

/// Tab „Karte“ erneut getippt: nach oben, ganz → halb.
final karteRetapProvider = NotifierProvider<SignalNotifier, int>(
  SignalNotifier.new,
);

/// Scroll-Position der Liste, damit sie Tabwechsel und Einzelansicht
/// überlebt.
final karteScrollProvider = NotifierProvider<KarteScrollNotifier, double>(
  KarteScrollNotifier.new,
);

class KarteScrollNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void set(double offset) => state = offset;
}

/// Ziel-Schlüssel für den Coach-Mark (Hören-Button der ersten Karte).
final coachTargetKeyProvider = Provider<GlobalKey>(
  (ref) => GlobalKey(debugLabel: 'coachHoeren'),
);

/// Katalog nach ID.
final trailsByIdProvider = Provider<Map<String, Trail>>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value ?? const <Trail>[];
  return {for (final t in trails) t.id: t};
});

/// Bezugspunkt-Koordinate fürs Rechnen, `null` bei E3.
final bezugCoordsProvider = Provider<LatLng?>(
  (ref) => ref.watch(aktuellerBezugProvider)?.coords,
);

/// Geschätzte Anfahrt eines Eintrags ab dem aktuellen Bezugspunkt.
final anfahrtMinProvider = Provider.family<int?, Eintrag>((ref, e) {
  final bezug = ref.watch(bezugCoordsProvider);
  return bezug == null ? null : schaetzeAnfahrtMin(bezug, e.startpunkt);
});

/// Bezugspunkt-Quelle als Kurzform, für Tracking und Icon.
final bezugQuelleProvider = Provider<BezugQuelle?>(
  (ref) => ref.watch(aktuellerBezugProvider)?.quelle,
);
