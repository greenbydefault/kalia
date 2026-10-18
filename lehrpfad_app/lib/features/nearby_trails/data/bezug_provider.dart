import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../location/location_permission_controller.dart';
import '../../location/user_position_provider.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../onboarding/data/place_search.dart';
import '../../onboarding/domain/user_place.dart';
import '../domain/bezugspunkt.dart';
import '../domain/karte_logik.dart';

const _zuletztKey = 'karte_zuletzt_gesucht';
const _kartenBezugKey = 'karte_bezug_karte';
const _umkreisKey = 'karte_umkreis';

/// Wie viele letzte Suchen die Ortssuche zeigt.
const zuletztMax = 3;

/// Anfahrt höchstens: derselbe State im Filter und in der Ortssuche.
final umkreisProvider = NotifierProvider<UmkreisNotifier, Umkreis>(
  UmkreisNotifier.new,
);

class UmkreisNotifier extends Notifier<Umkreis> {
  @override
  Umkreis build() {
    _load();
    return Umkreis.standard;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_umkreisKey);
    if (raw == null) return;
    final u = Umkreis.fromKey(raw);
    if (u != state) state = u;
  }

  Future<void> set(Umkreis umkreis) async {
    state = umkreis;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_umkreisKey, umkreis.key);
  }
}

/// Bezugspunkt aus „In diesem Bereich suchen“ plus die letzten Suchen.
/// GPS und gesuchter Ort liegen weiter in den Onboarding-Prefs (Ort und
/// Standort schließen sich aus).
class KarteBezugState {
  const KarteBezugState({
    this.karte,
    this.karteAktiv = false,
    this.zuletzt = const [],
  });

  /// Letzter Bezugspunkt mit Quelle Karte.
  final Bezugspunkt? karte;

  /// Nur in dieser Sitzung gesetzt: dann hat er Vorrang vor Ort und GPS.
  final bool karteAktiv;

  /// Neueste zuerst, höchstens [zuletztMax].
  final List<UserPlace> zuletzt;

  KarteBezugState copyWith({
    Bezugspunkt? karte,
    bool? karteAktiv,
    bool clearKarte = false,
    List<UserPlace>? zuletzt,
  }) => KarteBezugState(
    karte: clearKarte ? null : (karte ?? this.karte),
    karteAktiv: karteAktiv ?? this.karteAktiv,
    zuletzt: zuletzt ?? this.zuletzt,
  );
}

final karteBezugProvider =
    NotifierProvider<KarteBezugNotifier, KarteBezugState>(
      KarteBezugNotifier.new,
    );

class KarteBezugNotifier extends Notifier<KarteBezugState> {
  @override
  KarteBezugState build() {
    _load();
    return const KarteBezugState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zuletzt = <UserPlace>[];
      final raw = prefs.getString(_zuletztKey);
      if (raw != null) {
        for (final j in jsonDecode(raw) as List) {
          zuletzt.add(UserPlace.fromJson(j as Map<String, dynamic>));
        }
      }
      final kRaw = prefs.getString(_kartenBezugKey);
      state = state.copyWith(
        zuletzt: zuletzt,
        karte: kRaw == null ? null : Bezugspunkt.fromJson(jsonDecode(kRaw)),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _zuletztKey,
      jsonEncode([for (final p in state.zuletzt) p.toJson()]),
    );
    final karte = state.karte;
    if (karte == null) {
      await prefs.remove(_kartenBezugKey);
    } else {
      await prefs.setString(_kartenBezugKey, jsonEncode(karte.toJson()));
    }
  }

  /// Gewählter Ort wandert nach vorn, doppelte fliegen raus.
  Future<void> merkeOrt(UserPlace place) async {
    final liste = [
      place,
      for (final p in state.zuletzt)
        if (p != place) p,
    ].take(zuletztMax).toList();
    state = state.copyWith(zuletzt: liste, karteAktiv: false);
    await _save();
  }

  Future<void> setzeKarte(Bezugspunkt bezug) async {
    state = state.copyWith(karte: bezug, karteAktiv: true);
    await _save();
  }

  /// Startpunkt entfernt: auch die gemerkte Kartenmitte fällt weg.
  Future<void> loescheKarte() async {
    state = state.copyWith(clearKarte: true, karteAktiv: false);
    await _save();
  }

  /// Ort oder GPS wurde gewählt: die Kartenmitte gilt nicht mehr.
  void verwerfeKarte() {
    if (state.karteAktiv) state = state.copyWith(karteAktiv: false);
  }
}

/// Der Bezugspunkt, nach dem Liste, Marker und Anfahrt rechnen.
///
/// Reihenfolge: Kartenmitte dieser Sitzung, gewählter Ort, GPS, zuletzt
/// genutzte Kartenmitte. `null` = Zustand E3 (kein Startpunkt).
final aktuellerBezugProvider = Provider<Bezugspunkt?>((ref) {
  final kb = ref.watch(karteBezugProvider);
  if (kb.karteAktiv && kb.karte != null) return kb.karte;

  final place = ref.watch(onboardingPrefsValueProvider).place;
  if (place != null) {
    return Bezugspunkt(
      quelle: BezugQuelle.suche,
      coords: place.position,
      ortName: place.name,
    );
  }

  final enabled = ref.watch(mapLocationEnabledProvider);
  final fix = ref.watch(userPositionProvider).fix;
  if (enabled && fix != null) {
    final index = ref.watch(placeIndexProvider).asData?.value;
    return Bezugspunkt(
      quelle: BezugQuelle.gps,
      coords: fix.position,
      ortName: index?.nearest(fix.position)?.name,
    );
  }
  return kb.karte;
});

/// Zustand aus Berechtigung, Einwilligung und Positionsabfrage.
final standortZustandProvider = Provider<StandortZustand>((ref) {
  final pos = ref.watch(userPositionProvider);
  return bestimmeStandortZustand(
    status: ref.watch(locationPermissionProvider),
    enabled: ref.watch(mapLocationEnabledProvider),
    loading: pos.loading,
    hasFix: pos.fix != null,
    fehler: pos.lastError?.kind,
  );
});
