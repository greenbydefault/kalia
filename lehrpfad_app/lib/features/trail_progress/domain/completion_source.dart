/// Herkunft einer Gelaufen-Markierung.
enum CompletionSource {
  manual,
  gps;

  String get wire => name;

  static CompletionSource fromWire(String? value) {
    return value == 'gps' ? CompletionSource.gps : CompletionSource.manual;
  }
}
