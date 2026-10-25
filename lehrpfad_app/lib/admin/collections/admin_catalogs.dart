import '../../shared/catalogs/icon_catalog.dart';

/// Key → Label aus den App-Katalogen (`icon_catalog.dart`), damit Admin und
/// App dieselben Schlüssel und Namen benutzen.
Map<String, String> labelsOf(Map<String, KatalogEintrag> katalog) => {
  for (final e in katalog.entries) e.key: e.value.label,
};

final typOptions = labelsOf(typKatalog);
final tagOptions = labelsOf(tagKatalog);
final erlebnisOptions = labelsOf(erlebnisKatalog);
final amenityOptions = labelsOf(amenityKatalog);
final poiKategorieOptions = labelsOf(poiKategorieKatalog);
final gruppeOptions = labelsOf(speciesGruppeKatalog);
final seltenheitOptions = labelsOf(seltenheitKatalog);
final merkmaleIconOptions = labelsOf(merkmaleKatalog);
final geraeteIconOptions = labelsOf(geraeteKatalog);
final masseOptions = labelsOf(masseKatalog);

const formOptions = {'linie': 'Linie (Route)', 'flaeche': 'Fläche (Polygon)'};

const gefahrOptions = {
  '0': 'nicht gesetzt',
  '1': '1 · Sehr gering',
  '2': '2 · Gering',
  '3': '3 · Mittel',
  '4': '4 · Hoch',
  '5': '5 · Nicht annähern',
};

const naturraumOptions = {
  'nordsee': 'Nordsee',
  'ostsee': 'Ostsee',
  'norddt-tiefland': 'Norddeutsches Tiefland',
  'mittelgebirge': 'Mittelgebirge',
  'alpenvorland': 'Alpenvorland',
  'katalonien': 'Katalonien',
  'daenemark': 'Dänemark',
};

const merkmalGruppeOptions = {
  'aussehen': 'Aussehen',
  'verhalten': 'Verhalten',
  'rolle': 'Rolle',
  'lebensraum': 'Lebensraum',
};

const nachweisOptions = {
  'belegt': 'belegt (Tafel, Betreiber, Station)',
  'typisch': 'typisch (aus dem Pool)',
};

const poolRolleOptions = {
  'leit': 'Leitart',
  'typisch': 'typisch',
  'bonus': 'Bonus',
};

const poolSichtbarkeitOptions = {
  'leicht': 'leicht',
  'geduld': 'mit Geduld',
  'saison': 'saisonal',
  'nacht': 'nachts',
};

const poolSaisonOptions = {'ganzjaehrig': 'ganzjährig', 'saison': 'saisonal'};

const tiefeOptions = {
  'voll': 'voll (mit Hörtext)',
  'kurz': 'kurz (ohne Hörtext)',
};

const beziehungTypOptions = {
  'frisst': 'frisst',
  'bestaeubt': 'bestäubt',
  'wohnt_an': 'wohnt an',
};

const lizenzOptions = {
  '': 'keine Angabe',
  'cc-by-sa-4.0': 'CC BY-SA 4.0',
  'cc-by-sa-3.0': 'CC BY-SA 3.0',
  'cc-by-sa-2.0': 'CC BY-SA 2.0',
  'cc-by-4.0': 'CC BY 4.0',
  'cc-by-3.0': 'CC BY 3.0',
  'cc-by-2.0': 'CC BY 2.0',
  'cc0': 'CC0',
  'pd': 'Public Domain',
  'eigen': 'Eigenes Foto',
  'freigabe': 'Freigabe liegt vor (noch nicht bestätigt)',
};
