import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/nearby_trails/data/karte_state.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/bezugspunkt.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/eintrag.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/karte_logik.dart';
import 'package:lehrpfad_app/features/nearby_trails/presentation/hoeren_button.dart';
import 'package:lehrpfad_app/features/trail/domain/gebiet.dart';
import 'package:lehrpfad_app/features/trail_progress/tracking/location_service.dart';

void main() {
  group('Gebiet ableiten', () {
    test('typ gewinnt', () {
      expect(deriveGebiet('moor', ['heide']), Gebiet.moor);
      expect(deriveGebiet('kinderbauernhof', const []), Gebiet.hof);
      expect(deriveGebiet('wasserspielplatz', ['heide']), Gebiet.wasser);
    });

    test('sonst erster Lebensraum', () {
      expect(deriveGebiet('wanderweg', ['trockenrasen']), Gebiet.heide);
      expect(
        deriveGebiet('wanderweg', ['duene-strand', 'heide']),
        Gebiet.kueste,
      );
    });

    test('Fallback Wald', () {
      expect(deriveGebiet('wanderweg', const []), Gebiet.wald);
      expect(deriveGebiet('wanderweg', ['unbekannt']), Gebiet.wald);
    });

    test('fromKey', () {
      expect(Gebiet.fromKey('kueste'), Gebiet.kueste);
      expect(Gebiet.fromKey('x'), isNull);
    });
  });

  group('Filter-JSON', () {
    test('Runde ohne Verlust', () {
      const f = KarteFilter(
        arten: {EintragArt.weg},
        dauer: DauerBereich.von1bis2Std,
        laenge: LaengeBereich.bis5km,
        merkmale: {Merkmal.kinderwagen, Merkmal.wc},
      );
      expect(filterVonJson(filterZuJson(f)), f);
    });

    test('kaputte Daten ergeben Standard', () {
      expect(filterVonJson('quatsch'), KarteFilter.standard);
      expect(filterVonJson({'arten': <String>[]}).arten, hasLength(2));
    });
  });

  group('Bezugszeile', () {
    const coords = LatLng(52.5, 13.4);

    test('Ort mit Umkreis', () {
      final t = bezugszeileText(
        bezug: const Bezugspunkt(
          quelle: BezugQuelle.suche,
          coords: coords,
          ortName: 'Berlin',
        ),
        umkreis: Umkreis.min30,
      );
      expect(t, 'Rund um Berlin, bis 30 Min Anfahrt');
    });

    test('GPS ohne Namen', () {
      final t = bezugszeileText(
        bezug: const Bezugspunkt(quelle: BezugQuelle.gps, coords: coords),
        umkreis: Umkreis.egal,
      );
      expect(t, 'Rund um euren Standort, alle Entfernungen');
    });

    test('ohne Startpunkt und beim Ermitteln', () {
      expect(
        bezugszeileText(bezug: null, umkreis: Umkreis.min15),
        'Kein Startpunkt gewählt',
      );
      expect(
        bezugszeileText(bezug: null, umkreis: Umkreis.min15, ermittelt: true),
        'Standort wird ermittelt …',
      );
    });
  });

  group('Standort-Zustände', () {
    StandortZustand z({
      OsLocationStatus status = OsLocationStatus.whileInUse,
      bool enabled = true,
      bool loading = false,
      bool hasFix = true,
      LocationFailure? fehler,
    }) => bestimmeStandortZustand(
      status: status,
      enabled: enabled,
      loading: loading,
      hasFix: hasFix,
      fehler: fehler,
    );

    test('erteilt', () {
      expect(z(), StandortZustand.erteiltPositionDa);
      expect(z(loading: true, hasFix: false), StandortZustand.erteiltErmittelt);
      expect(
        z(hasFix: false, fehler: LocationFailure.timeout),
        StandortZustand.erteiltTimeout,
      );
    });

    test('abgelehnt', () {
      expect(z(status: OsLocationStatus.denied), StandortZustand.abgelehnt);
      expect(z(enabled: false), StandortZustand.abgelehnt);
      expect(
        z(status: OsLocationStatus.deniedForever),
        StandortZustand.dauerhaftAbgelehnt,
      );
    });
  });

  group('Hören-Zustand', () {
    HoerenZustand h({
      bool aktuell = false,
      bool playing = false,
      bool loading = false,
      bool offline = false,
    }) => bestimmeHoerenZustand(
      aktuell: aktuell,
      playing: playing,
      loading: loading,
      offlineOhneDatei: offline,
    );

    test('Zustände', () {
      expect(h(), HoerenZustand.bereit);
      expect(h(offline: true), HoerenZustand.offline);
      expect(h(aktuell: true, loading: true), HoerenZustand.laedt);
      expect(h(aktuell: true, playing: true), HoerenZustand.spielt);
      expect(h(aktuell: true), HoerenZustand.pausiert);
      // Läuft der Eintrag schon, sperrt Offline ihn nicht.
      expect(
        h(aktuell: true, playing: true, offline: true),
        HoerenZustand.spielt,
      );
    });
  });
}
