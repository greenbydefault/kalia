import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell-Tab-Index (Karte=0, Erkunden=1, Meine Listen=2, Sammlung=3, Konto=4).
final shellTabIndexProvider = NotifierProvider<ShellTabIndexNotifier, int>(
  ShellTabIndexNotifier.new,
);

class ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void goTo(int index) => state = index;

  void goToMap() => state = 0;
}
