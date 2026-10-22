import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/offline/offline.dart';
import 'audio_playback_service.dart';

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService(
    resolve: (path) => ref
        .read(assetResolverProvider)
        .audio(AudioRef(path), online: ref.read(isOnlineProvider)),
  );
  ref.onDispose(service.dispose);
  return service;
});
