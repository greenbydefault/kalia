/// OSM-`opening_hours`-Subset für kuratierte Orte.
///
/// Unterstützt: Wochentage (`Mo`-`Su`, Ranges, Listen), Uhrzeiten
/// (`hh:mm-hh:mm`, mehrere per Komma), Monats-Saison (`Apr-Oct:`), `off`,
/// Regel-Trenner `;`. Alles außerhalb → [OeffnungsStatus.unbekannt].
enum OeffnungsStatus { offen, geschlossen, unbekannt }

/// Wertet [openingHours] zum Zeitpunkt [now] aus.
OeffnungsStatus oeffnungsStatus(String? openingHours, DateTime now) {
  if (openingHours == null || openingHours.trim().isEmpty) {
    return OeffnungsStatus.unbekannt;
  }
  final rules = _parse(openingHours.trim());
  if (rules == null) return OeffnungsStatus.unbekannt;

  _Rule? lastMatch;
  for (final rule in rules) {
    if (rule.matchesSelectors(now)) lastMatch = rule;
  }
  if (lastMatch == null) return OeffnungsStatus.geschlossen;
  if (lastMatch.off) return OeffnungsStatus.geschlossen;
  if (lastMatch.intervals.isEmpty) return OeffnungsStatus.offen;
  final minutes = now.hour * 60 + now.minute;
  return lastMatch.isOpenAt(minutes)
      ? OeffnungsStatus.offen
      : OeffnungsStatus.geschlossen;
}

const _months = <String, int>{
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

const _weekdays = <String, int>{
  'Mo': DateTime.monday,
  'Tu': DateTime.tuesday,
  'We': DateTime.wednesday,
  'Th': DateTime.thursday,
  'Fr': DateTime.friday,
  'Sa': DateTime.saturday,
  'Su': DateTime.sunday,
};

final _monthRe = RegExp(
  r'^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
  r'(?:-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))?:?\s*',
);

final _daysRe = RegExp(
  r'^((?:Mo|Tu|We|Th|Fr|Sa|Su)(?:-(?:Mo|Tu|We|Th|Fr|Sa|Su))?'
  r'(?:,(?:Mo|Tu|We|Th|Fr|Sa|Su)(?:-(?:Mo|Tu|We|Th|Fr|Sa|Su))?)*)\s*',
);

final _intervalRe = RegExp(r'^(\d{2}):(\d{2})-(\d{2}):(\d{2})$');

List<_Rule>? _parse(String input) {
  final rules = <_Rule>[];
  for (final part in input.split(';')) {
    final rule = _parseRule(part.trim());
    if (rule == null) return null;
    rules.add(rule);
  }
  return rules;
}

_Rule? _parseRule(String raw) {
  if (raw.isEmpty) return null;
  var rest = raw;

  int? monthFrom;
  int? monthTo;
  final monthMatch = _monthRe.firstMatch(rest);
  if (monthMatch != null) {
    monthFrom = _months[monthMatch[1]!];
    monthTo = monthMatch[2] != null ? _months[monthMatch[2]!] : monthFrom;
    rest = rest.substring(monthMatch.end).trim();
  }

  Set<int>? days;
  final daysMatch = _daysRe.firstMatch(rest);
  if (daysMatch != null) {
    days = _expandDays(daysMatch[1]!);
    if (days == null) return null;
    rest = rest.substring(daysMatch.end).trim();
  }

  if (rest.isEmpty || rest == 'off' || rest == 'closed') {
    return _Rule(
      monthFrom: monthFrom,
      monthTo: monthTo,
      days: days,
      off: rest == 'off' || rest == 'closed',
    );
  }

  final intervals = _parseIntervals(rest);
  if (intervals == null) return null;
  return _Rule(
    monthFrom: monthFrom,
    monthTo: monthTo,
    days: days,
    intervals: intervals,
  );
}

Set<int>? _expandDays(String spec) {
  final out = <int>{};
  for (final item in spec.split(',')) {
    final parts = item.split('-');
    if (parts.length == 1) {
      final d = _weekdays[parts[0]];
      if (d == null) return null;
      out.add(d);
      continue;
    }
    if (parts.length != 2) return null;
    final start = _weekdays[parts[0]];
    final end = _weekdays[parts[1]];
    if (start == null || end == null) return null;
    var cursor = start;
    while (true) {
      out.add(cursor);
      if (cursor == end) break;
      cursor = cursor == DateTime.sunday ? DateTime.monday : cursor + 1;
    }
  }
  return out;
}

List<_Interval>? _parseIntervals(String spec) {
  final out = <_Interval>[];
  for (final part in spec.split(',')) {
    final m = _intervalRe.firstMatch(part.trim());
    if (m == null) return null;
    final sh = int.parse(m[1]!);
    final sm = int.parse(m[2]!);
    final eh = int.parse(m[3]!);
    final em = int.parse(m[4]!);
    if (sh > 24 || eh > 24 || sm > 59 || em > 59) return null;
    if (sh == 24 && sm != 0) return null;
    if (eh == 24 && em != 0) return null;
    out.add(_Interval(sh * 60 + sm, eh * 60 + em));
  }
  return out;
}

class _Rule {
  final int? monthFrom;
  final int? monthTo;
  final Set<int>? days;
  final bool off;
  final List<_Interval> intervals;

  const _Rule({
    this.monthFrom,
    this.monthTo,
    this.days,
    this.off = false,
    this.intervals = const [],
  });

  bool matchesSelectors(DateTime now) {
    if (monthFrom != null) {
      final from = monthFrom!;
      final to = monthTo ?? from;
      final month = now.month;
      final inRange = from <= to
          ? month >= from && month <= to
          : month >= from || month <= to;
      if (!inRange) return false;
    }
    if (days != null && !days!.contains(now.weekday)) return false;
    return true;
  }

  bool isOpenAt(int minutes) {
    for (final interval in intervals) {
      if (interval.contains(minutes)) return true;
    }
    return false;
  }
}

class _Interval {
  final int start;
  final int end;

  const _Interval(this.start, this.end);

  bool contains(int minutes) {
    if (end > start) return minutes >= start && minutes < end;
    if (end == start) return true;
    return minutes >= start || minutes < end;
  }
}
