import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/connectivity/offline_provider.dart';
import '../../../core/media/media_url.dart';
import '../../player/data/mini_player_provider.dart';
import '../../trail/domain/trail.dart';
import '../domain/eintrag.dart';
import '../domain/karte_copy.dart';

/// Zustände des Hören-Buttons (Spec Abschnitt 8).
enum HoerenZustand { bereit, laedt, spielt, pausiert, offline }

HoerenZustand bestimmeHoerenZustand({
  required bool aktuell,
  required bool playing,
  required bool loading,
  required bool offlineOhneDatei,
}) {
  if (aktuell) {
    if (loading) return HoerenZustand.laedt;
    return playing ? HoerenZustand.spielt : HoerenZustand.pausiert;
  }
  return offlineOhneDatei ? HoerenZustand.offline : HoerenZustand.bereit;
}

/// Startet das erste Audio des Eintrags im Mini-Player. Ist der Eintrag
/// gerade im Player, zeigt der Button „spielt“ oder „pausiert“.
class HoerenButton extends ConsumerWidget {
  const HoerenButton({
    super.key,
    required this.trail,
    required this.audio,
    this.onGestartet,
  });

  final Trail trail;
  final EintragAudio audio;

  /// Nach erfolgreichem Start (Tracking, Coach-Mark).
  final VoidCallback? onGestartet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      miniPlayerProvider.select(
        (s) => s != null && s.trail.id == trail.id
            ? (playing: s.playing, loading: s.loading)
            : null,
      ),
    );
    final offline = ref.watch(offlineProvider);
    final zustand = bestimmeHoerenZustand(
      aktuell: status != null,
      playing: status?.playing ?? false,
      loading: status?.loading ?? false,
      offlineOhneDatei: offline && MediaUrl.isNetwork(audio.url),
    );

    final (text, icon) = switch (zustand) {
      HoerenZustand.bereit => (kt('hoeren.bereit'), PhosphorIcons.play),
      HoerenZustand.laedt => (kt('hoeren.laedt'), null),
      HoerenZustand.spielt => (kt('hoeren.pause'), PhosphorIcons.pause),
      HoerenZustand.pausiert => (kt('hoeren.weiter'), PhosphorIcons.play),
      HoerenZustand.offline => (kt('hoeren.offline'), PhosphorIcons.play),
    };
    final gesperrt =
        zustand == HoerenZustand.laedt || zustand == HoerenZustand.offline;
    final spielt = zustand == HoerenZustand.spielt;

    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      shape: const StadiumBorder(),
    );
    final leading = icon == null
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : PhosphorIcon(icon, size: 18);
    final onPressed = gesperrt ? null : () => _tippen(context, ref);

    // Spielt: hervorgehoben (Primärfarbe). Sonst zurückgenommen.
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: spielt
          ? FilledButton.icon(
              style: style,
              onPressed: onPressed,
              icon: leading,
              label: Text(text),
            )
          : FilledButton.tonalIcon(
              style: style,
              onPressed: onPressed,
              icon: leading,
              label: Text(text),
            ),
    );
  }

  Future<void> _tippen(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(miniPlayerProvider.notifier).play(trail, audio);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(kt('fehler.audio')),
          ),
        );
      return;
    }
    onGestartet?.call();
  }
}
