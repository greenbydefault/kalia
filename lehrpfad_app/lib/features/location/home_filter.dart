import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter-Chips unter „Nächste Wege“ (Länge, Kinderwagen). Wirken auf Liste
/// und Karte. Standard: alles aus dem Onboarding aktiv.
class HomeFilter {
  const HomeFilter({this.lengthOn = true, this.strollerOn = true});

  final bool lengthOn;
  final bool strollerOn;
}

final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(
  HomeFilterNotifier.new,
);

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => const HomeFilter();

  void toggleLength() => state = HomeFilter(
    lengthOn: !state.lengthOn,
    strollerOn: state.strollerOn,
  );

  void toggleStroller() => state = HomeFilter(
    lengthOn: state.lengthOn,
    strollerOn: !state.strollerOn,
  );

  /// Beide Schalter aus, z. B. wenn ein Weg gezielt geöffnet wird.
  void clear() => state = const HomeFilter(lengthOn: false, strollerOn: false);
}
