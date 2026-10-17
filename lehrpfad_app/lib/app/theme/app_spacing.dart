/// 4px-Raster für Abstände, plus Rollen für den Trail-Inhalt.
///
/// Call-Sites nehmen eine Rolle (`page`, `afterHeading`, `stack`, `section`,
/// `chip`). Das Raster (`x1`–`x8`) bleibt für Chrome, das keine Rolle hat.
/// Eine Rolle hier nachziehen verschiebt jede Stelle, die sie nutzt.
abstract final class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;

  /// Links, rechts und oben am Content.
  static const double page = x4;

  /// Titel zu seinem Text, Abschnittstitel zu seinem Inhalt.
  static const double afterHeading = x2;

  /// Nächster Block in derselben Sektion (Chips, Meter, Tags, Aktion, Absatz).
  static const double stack = x4;

  /// Neue Sektion.
  static const double section = x6;

  /// Abstand der Chips untereinander.
  static const double chip = x2;
}
