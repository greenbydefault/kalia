import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/offline/resolver/asset_resolver.dart';
import '../media/media_url.dart';

/// Ein zentraler Player für die ganze App.
///
/// Ein einziger [AudioPlayer] verhindert Overlap zwischen Arten-/Stations-Audio.
class AudioPlaybackService {
  /// [resolve] entscheidet die Quelle (lokale Datei → Netz → Bundle-Asset,
  /// siehe `AssetResolver.audio`). Ohne Resolver: wie bisher Asset oder URL.
  AudioPlaybackService({this._resolve});

  final ResolvedAudio? Function(String path)? _resolve;
  final AudioPlayer _player = AudioPlayer();
  String? _currentSource;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Duration get position => _player.position;
  Future<void> seek(Duration position) => _player.seek(position);
  void resume() => _player.play();
  bool get playing => _player.playing;
  String? get currentSource => _currentSource;

  /// Lädt die Quelle, ohne zu spielen. Gebündeltes Asset oder, bei
  /// `http(s)://` bzw. `storage:`-Pfaden (Admin-CMS), die Datei aus dem Netz.
  Future<void> prepare(String assetPath) async {
    if (_currentSource == assetPath) return;
    final resolve = _resolve;
    if (resolve != null) {
      switch (resolve(assetPath)) {
        case AudioFileSource(:final path):
          await _player.setFilePath(path);
        case AudioUrlSource(:final url):
          await _player.setUrl(url);
        case AudioAssetSource(:final path):
          await _player.setAsset(path);
        case null:
          throw StateError('Audio offline nicht verfügbar: $assetPath');
      }
    } else {
      final url = MediaUrl.resolve(assetPath);
      if (url != null) {
        await _player.setUrl(url);
      } else {
        await _player.setAsset(assetPath);
      }
    }
    _currentSource = assetPath;
  }

  /// Spielt ein gebuendeltes Asset oder, bei `http(s)://` bzw.
  /// `storage:`-Pfaden (Admin-CMS), die Datei aus dem Netz.
  Future<void> playAsset(String assetPath) async {
    try {
      await prepare(assetPath);
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
