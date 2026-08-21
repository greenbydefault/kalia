import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_playback_service.dart';

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});
