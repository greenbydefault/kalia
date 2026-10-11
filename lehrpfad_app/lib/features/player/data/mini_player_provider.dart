import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trail/domain/trail.dart';

/// Was der Mini-Player gerade zeigt.
class MiniPlayerState {
  const MiniPlayerState({
    required this.trail,
    required this.stationTitle,
    this.playing = true,
    this.progress = 0,
  });

  final Trail trail;
  final String stationTitle;
  final bool playing;

  /// 0..1
  final double progress;

  MiniPlayerState copyWith({bool? playing, double? progress}) {
    return MiniPlayerState(
      trail: trail,
      stationTitle: stationTitle,
      playing: playing ?? this.playing,
      progress: progress ?? this.progress,
    );
  }
}

final miniPlayerProvider =
    NotifierProvider<MiniPlayerNotifier, MiniPlayerState?>(
      MiniPlayerNotifier.new,
    );

/// Hören-State. Solange Trails kein Audio-Asset haben, läuft der Fortschritt
/// simuliert ([placeholderDuration]); die echte Anbindung an
/// `AudioPlaybackService` kommt mit einem `audioPath` am Trail.
class MiniPlayerNotifier extends Notifier<MiniPlayerState?> {
  static const placeholderDuration = Duration(seconds: 90);
  static const _tick = Duration(milliseconds: 250);

  Timer? _timer;

  @override
  MiniPlayerState? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  bool isPlaying(String trailId) {
    final s = state;
    return s != null && s.trail.id == trailId && s.playing;
  }

  /// Startet [trail] oder pausiert/setzt fort, wenn er schon läuft.
  void play(Trail trail) {
    final s = state;
    if (s != null && s.trail.id == trail.id) {
      toggle();
      return;
    }
    state = MiniPlayerState(
      trail: trail,
      stationTitle: trail.stationen.isNotEmpty
          ? trail.stationen.first.titel
          : 'Einführung',
    );
    _start();
  }

  void toggle() {
    final s = state;
    if (s == null) return;
    if (s.playing) {
      _timer?.cancel();
      state = s.copyWith(playing: false);
    } else {
      state = s.copyWith(playing: true, progress: s.progress >= 1 ? 0 : null);
      _start();
    }
  }

  void stop() {
    _timer?.cancel();
    state = null;
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      final s = state;
      if (s == null || !s.playing) return;
      final next =
          s.progress +
          _tick.inMilliseconds / placeholderDuration.inMilliseconds;
      if (next >= 1) {
        _timer?.cancel();
        state = s.copyWith(playing: false, progress: 1);
      } else {
        state = s.copyWith(progress: next);
      }
    });
  }
}
