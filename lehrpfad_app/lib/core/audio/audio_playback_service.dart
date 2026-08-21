import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Ein zentraler Player für die ganze App.
///
/// Ein einziger [AudioPlayer] verhindert Overlap zwischen Arten-/Stations-Audio.
class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentSource;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get playing => _player.playing;
  String? get currentSource => _currentSource;

  Future<void> playAsset(String assetPath) async {
    try {
      if (_currentSource != assetPath) {
        await _player.setAsset(assetPath);
        _currentSource = assetPath;
      }
      await _player.play();
    } catch (e, st) {
      debugPrint('AudioPlaybackService.playAsset failed ($assetPath): $e\n$st');
      rethrow;
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    _currentSource = null;
  }

  Future<void> dispose() => _player.dispose();
}
