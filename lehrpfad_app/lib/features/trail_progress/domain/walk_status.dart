/// Lebenszyklus einer Tour.
enum WalkStatus {
  active,
  completed,
  abandoned;

  String get wire => name;

  static WalkStatus fromWire(String? value) {
    return switch (value) {
      'completed' => WalkStatus.completed,
      'abandoned' => WalkStatus.abandoned,
      _ => WalkStatus.active,
    };
  }
}
