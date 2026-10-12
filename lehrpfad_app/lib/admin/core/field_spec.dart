/// Zeile einer Katalog-Tabelle (snake_case-Spalten, wie von PostgREST).
typedef DbRow = Map<String, dynamic>;

enum FieldKind {
  /// Einzeiliger Text.
  text,

  /// Mehrzeiliger Text, optional mit Zeichen-/Wortlimit.
  longText,

  /// Zahl mit Nachkommastellen.
  number,

  /// Ganzzahl.
  integer,

  /// Schalter.
  boolean,

  /// Dropdown aus [FieldSpec.options] (Key → Label), leer erlaubt.
  select,

  /// Mehrfachauswahl aus [FieldSpec.options] (text[]).
  multiSelect,

  /// Freie Liste von Begriffen (text[]), Chips mit Eingabe.
  tags,

  /// Liste von Zeilen (jsonb-Array oder text[]), eine pro Textzeile.
  lines,
}

enum LimitUnit { chars, words }

/// Weiche Längenvorgabe. Nur Warnung, blockiert nie das Speichern.
class FieldLimit {
  const FieldLimit({this.min, this.max, this.unit = LimitUnit.chars});

  final int? min;
  final int? max;
  final LimitUnit unit;

  int measure(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return unit == LimitUnit.chars ? t.length : t.split(RegExp(r'\s+')).length;
  }

  /// `null` wenn im Rahmen, sonst kurze Warnung.
  String? warn(String text) {
    final n = measure(text);
    if (n == 0) return null;
    final label = unit == LimitUnit.chars ? 'Zeichen' : 'Wörter';
    if (max != null && n > max!) return '$n von max. $max $label';
    if (min != null && n < min!) return '$n von min. $min $label';
    return null;
  }

  String counter(String text) {
    final n = measure(text);
    final label = unit == LimitUnit.chars ? 'Zeichen' : 'Wörter';
    if (min != null && max != null) return '$n · $min–$max $label';
    if (max != null) return '$n / $max $label';
    if (min != null) return '$n · min. $min $label';
    return '$n $label';
  }
}

/// Ein editierbares Feld einer Zeile. Spalte [key], optional als
/// Schlüssel in einer jsonb-Spalte [json] (`content.hook`).
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.kind, {
    this.options = const {},
    this.limit,
    this.hint,
    this.json,
    this.readOnly = false,
    this.required = false,
    this.nullable = false,
    this.minLines = 1,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final Map<String, String> options;
  final FieldLimit? limit;
  final String? hint;

  /// Name der jsonb-Spalte, wenn [key] ein Schlüssel darin ist.
  final String? json;
  final bool readOnly;
  final bool required;

  /// Leer speichern als `null` statt `''` (Spalte ohne `not null`).
  final bool nullable;
  final int minLines;

  /// Rohwert aus der Zeile.
  dynamic read(DbRow row) {
    final j = json;
    if (j == null) return row[key];
    final m = row[j];
    return m is Map ? m[key] : null;
  }

  /// Wert als Anzeige-Text (für Text-Felder).
  String readText(DbRow row) {
    final v = read(row);
    if (v == null) return '';
    if (v is num && kind == FieldKind.number) {
      return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    }
    return v.toString();
  }

  List<String> readList(DbRow row) {
    final v = read(row);
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}
