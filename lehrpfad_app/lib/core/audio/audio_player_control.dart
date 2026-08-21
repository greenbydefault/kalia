import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/app_colors.dart';
import 'audio_providers.dart';

/// Wiederverwendbares Play/Pause-Control für Asset-Audio.
///
/// Nutzt den zentralen [audioPlaybackServiceProvider], damit nicht mehrere
/// Quellen gleichzeitig laufen.
class AudioPlayerControl extends ConsumerStatefulWidget {
  const AudioPlayerControl({
    super.key,
    required this.assetPath,
    this.playLabel = 'Stimme anhören',
    this.iconOnly = false,
  });

  final String assetPath;
  final String playLabel;

  /// Nur Icon-Button (44×44), ohne Label — für Species-Karten.
  final bool iconOnly;

  @override
  ConsumerState<AudioPlayerControl> createState() => _AudioPlayerControlState();
}

class _AudioPlayerControlState extends ConsumerState<AudioPlayerControl> {
  bool _loading = false;
  String? _error;

  Future<void> _toggle() async {
    final service = ref.read(audioPlaybackServiceProvider);
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final isThisSource = service.currentSource == widget.assetPath;
      if (isThisSource && service.playing) {
        await service.pause();
      } else {
        await service.playAsset(widget.assetPath);
      }
    } catch (e, st) {
      debugPrint(
        'AudioPlayerControl._toggle failed (${widget.assetPath}): $e\n$st',
      );
      if (mounted) {
        setState(() => _error = 'Audio konnte nicht geladen werden.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.watch(audioPlaybackServiceProvider);

    return StreamBuilder<PlayerState>(
      stream: service.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isThisSource = service.currentSource == widget.assetPath;
        final playing = isThisSource && (state?.playing ?? false);
        final processing = state?.processingState;

        if (isThisSource && processing == ProcessingState.completed) {
          // Zurück auf Anfang, damit erneutes Abspielen funktioniert.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            service.pause();
          });
        }

        final playIcon = PhosphorIcon(
          playing ? PhosphorIcons.pause : PhosphorIcons.play,
          size: widget.iconOnly ? 22 : 20,
          color: widget.iconOnly ? AppColors.ink : null,
        );

        if (widget.iconOnly) {
          return IconButton(
            tooltip: playing ? 'Stoppen' : widget.playLabel,
            onPressed: _loading ? null : _toggle,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: playIcon,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _loading ? null : _toggle,
              icon: playIcon,
              label: Text(playing ? 'Stoppen' : widget.playLabel),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
