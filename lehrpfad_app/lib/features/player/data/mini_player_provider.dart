import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/audio_providers.dart';
import '../../nearby_trails/domain/eintrag.dart';
import '../../trail/domain/trail.dart';

/// Was der Mini-Player gerade zeigt.
class MiniPlayerState {
  const MiniPlayerState({
    required this.trail,
    required this.audio,
    this.playing = false,
    this.loading = false,
    this.position = Duration.zero,
  });

  final Trail trail;
  final EintragAudio audio;
  final bool playing;
  final bool loading;
  final Duration position;

  String get titel => audio.titel;

  Duration get dauer => Duration(seconds: audio.dauerSek);

  /// 0..1
  double get progress {
    final ms = dauer.inMilliseconds;
    if (ms <= 0) return 0;
    return (position.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  /// Am Ende bleibt der Player mit Play-Icon stehen.
  bool get ended => position >= dauer;

  MiniPlayerState copyWith({
    bool? playing,
    bool? loading,
    Duration? position,
  }) => MiniPlayerState(
    trail: trail,
    audio: audio,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    position: position ?? this.position,
  );
}

final miniPlayerProvider =
    NotifierProvider<MiniPlayerNotifier, MiniPlayerState?>(
      MiniPlayerNotifier.new,
    );

/// „0:42“ bzw. „3:10“.
String formatZeit(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Ab diesem Anteil gilt ein Audio als zu Ende gehört: der nächste Start
/// beginnt von vorn.
const nahezuFertig = 0.9;

String _posKey(String trailId) => 'audio_pos_$trailId';

/// Hören-State. Es läuft immer nur ein Audio; ein neuer Eintrag ersetzt das
/// laufende. Mit Datei (`audio.url`) spielt der zentrale
/// [AudioPlaybackService], ohne Datei läuft der Fortschritt simuliert über
/// die geschätzte Dauer (TODO: Aufnahmen einspielen).
class MiniPlayerNotifier extends Notifier<MiniPlayerState?> {
  static const _tick = Duration(milliseconds: 250);

  Timer? _timer;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  MiniPlayerState? build() {
    ref.onDispose(_cancel);
    return null;
  }

  bool isPlaying(String trailId) {
    final s = state;
    return s != null && s.trail.id == trailId && s.playing;
  }

  bool get _echt => (state?.audio.url ?? '').isNotEmpty;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _posSub?.cancel();
    _posSub = null;
    _stateSub?.cancel();
    _stateSub = null;
  }

  Future<void> _speichere() async {
    final s = state;
    if (s == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_posKey(s.trail.id), s.position.inMilliseconds);
    } catch (_) {}
  }

  Future<Duration> _gespeichert(String trailId, EintragAudio audio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_posKey(trailId));
      if (ms == null) return Duration.zero;
      final total = audio.dauerSek * 1000;
      if (total <= 0 || ms >= total * nahezuFertig) return Duration.zero;
      return Duration(milliseconds: ms);
    } catch (_) {
      return Duration.zero;
    }
  }

  /// Startet [audio] von [trail] oder pausiert/setzt fort, wenn es schon
  /// läuft. `false`, wenn das Laden scheitert.
  Future<bool> play(Trail trail, EintragAudio audio) async {
    final s = state;
    if (s != null && s.trail.id == trail.id) {
      await toggle();
      return true;
    }
    await _speichere();
    if (s != null && _echt) await ref.read(audioPlaybackServiceProvider).stop();
    _cancel();
    final start = await _gespeichert(trail.id, audio);
    final echt = audio.url.isNotEmpty;
    state = MiniPlayerState(
      trail: trail,
      audio: audio,
      loading: echt,
      playing: !echt,
      position: start,
    );
    if (!echt) {
      _startSimuliert();
      return true;
    }
    try {
      final service = ref.read(audioPlaybackServiceProvider);
      await service.prepare(audio.url);
      if (start > Duration.zero) await service.seek(start);
      _hoere(service.positionStream, service.playerStateStream);
      service.resume();
      state = state?.copyWith(loading: false, playing: true);
      return true;
    } catch (_) {
      _cancel();
      state = null;
      return false;
    }
  }

  void _hoere(Stream<Duration> pos, Stream<PlayerState> player) {
    _posSub = pos.listen((p) {
      final s = state;
      if (s != null) state = s.copyWith(position: p);
    });
    _stateSub = player.listen((p) {
      final s = state;
      if (s == null || s.loading) return;
      if (p.processingState == ProcessingState.completed) {
        state = s.copyWith(playing: false, position: s.dauer);
        _speichere();
      } else if (p.playing != s.playing) {
        state = s.copyWith(playing: p.playing);
      }
    });
  }

  Future<void> toggle() async {
    final s = state;
    if (s == null || s.loading) return;
    if (_echt) {
      final service = ref.read(audioPlaybackServiceProvider);
      if (s.playing) {
        await service.pause();
        await _speichere();
      } else {
        if (s.ended) await service.seek(Duration.zero);
        service.resume();
      }
      return;
    }
    if (s.playing) {
      _timer?.cancel();
      state = s.copyWith(playing: false);
      await _speichere();
    } else {
      state = s.copyWith(
        playing: true,
        position: s.ended ? Duration.zero : null,
      );
      _startSimuliert();
    }
  }

  /// Schließen stoppt das Audio und merkt die Position.
  Future<void> stop() async {
    await _speichere();
    final echt = _echt;
    _cancel();
    state = null;
    if (echt) await ref.read(audioPlaybackServiceProvider).stop();
  }

  void _startSimuliert() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      final s = state;
      if (s == null || !s.playing) return;
      final next = s.position + _tick;
      if (next >= s.dauer) {
        _timer?.cancel();
        state = s.copyWith(playing: false, position: s.dauer);
        _speichere();
      } else {
        state = s.copyWith(position: next);
      }
    });
  }
}
