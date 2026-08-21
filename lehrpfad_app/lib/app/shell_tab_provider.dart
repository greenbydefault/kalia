import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell-Tab-Index (Karte=0, Meine Listen=1, Sammlung=2, Konto=3).
final shellTabIndexProvider = NotifierProvider<ShellTabIndexNotifier, int>(
  ShellTabIndexNotifier.new,
);

class ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void goTo(int index) => state = index;

  void goToMap() => state = 0;
}
