/// Grobe Anfahrtszeit mit dem Auto aus der Luftlinie.
///
/// Faktor 1,3 für Umweg, 60 km/h im Schnitt, gerundet auf 5 Minuten ab
/// 15 Minuten. Keine Routingdaten, daher „ca.“.
int anfahrtMinuten(double distanceM) {
  final minutes = distanceM / 1000 * 1.3;
  final rounded = minutes >= 15 ? (minutes / 5).round() * 5 : minutes.round();
  return rounded < 1 ? 1 : rounded;
}

String anfahrtLabel(double distanceM) {
  final min = anfahrtMinuten(distanceM);
  if (min < 60) return 'ca. $min Min mit dem Auto';
  final h = min ~/ 60;
  final m = min % 60;
  return m == 0 ? 'ca. $h Std mit dem Auto' : 'ca. $h Std $m Min mit dem Auto';
}
