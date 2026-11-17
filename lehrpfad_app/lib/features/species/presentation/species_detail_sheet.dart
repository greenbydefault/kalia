import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/audio/audio_player_control.dart';
import '../../../core/audio/audio_providers.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../nearby_trails/domain/karte_logik.dart';
import '../data/sammlung_providers.dart';
import '../data/species_providers.dart';
import '../domain/fund.dart';
import '../domain/sammlung_ansicht.dart';
import '../domain/species.dart';
import 'species_content_view.dart';
import 'species_illustration.dart';
import 'species_profil_view.dart';
import 'species_section_title.dart';

/// Detail zu einer Art / einem Gerät, in zwei Varianten: gefunden und offen.
///
/// Reihenfolge nach docs/sammlung/umbau-spec.md: Bühne · Kopf · Aktionen ·
/// Kontext · Wusstest du? · Wer hat’s entdeckt? · Steckbrief · Entfernen.
class SpeciesDetailSheet extends ConsumerStatefulWidget {
  const SpeciesDetailSheet({super.key, required this.species, this.trailId});

  final Species species;

  /// Trail-Kontext: Pfad des Funds beim Freischalten. Ohne: nächster Pfad.
  final String? trailId;

  static Future<void> show(
    BuildContext context,
    Species species, {
    String? trailId,
  }) {
    final container = ProviderScope.containerOf(context);
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => SpeciesDetailSheet(species: species, trailId: trailId),
    ).whenComplete(
      () => container.read(sammlungFrischProvider.notifier).setze(null),
    );
  }

  @override
  ConsumerState<SpeciesDetailSheet> createState() => _SpeciesDetailSheetState();
}

class _SpeciesDetailSheetState extends ConsumerState<SpeciesDetailSheet> {
  bool _entfernenFrage = false;
  bool _neu = false;

  Species get _s => widget.species;

  @override
  void dispose() {
    // Schließen stoppt das Audio dieser Art, fremde Wiedergabe bleibt.
    if (_s.hasPlayableAudio) {
      final service = ref.read(audioPlaybackServiceProvider);
      if (service.currentSource == _s.audioPath) service.stop();
    }
    super.dispose();
  }

  Future<void> _freischalten() async {
    final trailId =
        widget.trailId ??
        ref.read(chancenFuerProvider(_s.id)).firstOrNull?.trail.id;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(fundeProvider.notifier).entdecke(_s.id, trailId: trailId);
    ref.read(sammlungFrischProvider.notifier).setze(_s.id);
    if (!mounted) return;
    setState(() => _neu = true);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${_s.nameDe} ist jetzt in eurer Sammlung'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _entfernen() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(fundeProvider.notifier);
    final fund = await notifier.entferne(_s.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${_s.nameDe} entfernt'),
        duration: const Duration(seconds: 4),
        action: fund == null
            ? null
            : SnackBarAction(
                label: 'Rückgängig',
                onPressed: () => notifier.wiederherstellen(fund),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fund = ref.watch(fundeProvider).asData?.value[_s.id];
    final gefunden = fund != null;
    final factOben = _s.content.funFacts.isEmpty
        ? null
        : _s.content.funFacts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Buehne(species: _s, gefunden: gefunden, neu: _neu),
        const SizedBox(height: AppSpacing.stack),
        _Kopf(species: _s),
        const SizedBox(height: AppSpacing.stack),
        _Aktionen(
          species: _s,
          gefunden: gefunden,
          onFreischalten: _freischalten,
        ),
        _Kontext(species: _s, fund: fund),
        if (factOben != null) ...[
          const SizedBox(height: AppSpacing.stack),
          const SpeciesSectionTitle(title: 'Wusstest du?'),
          const SizedBox(height: AppSpacing.afterHeading),
          Text(
            factOben,
            key: const ValueKey('sheet-wusstest-du'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (fund != null) ...[
          const SizedBox(height: AppSpacing.stack),
          _Wer(
            von: fund.von,
            onChanged: (v) =>
                ref.read(fundeProvider.notifier).setzeVon(_s.id, v),
          ),
        ],
        const SizedBox(height: AppSpacing.section),
        SpeciesContentView(
          species: _s,
          showAudio: false,
          skipFirstFunFact: factOben != null,
        ),
        SpeciesProfilView(species: _s),
        if (gefunden) ...[
          const SizedBox(height: AppSpacing.stack),
          _Entfernen(
            frage: _entfernenFrage,
            onFrage: (v) => setState(() => _entfernenFrage = v),
            onEntfernen: _entfernen,
          ),
        ],
      ],
    );
  }
}

/// Illustration (sonst Icon) farbig oder als Silhouette, Schließen-Button.
class _Buehne extends StatelessWidget {
  const _Buehne({
    required this.species,
    required this.gefunden,
    required this.neu,
  });

  final Species species;
  final bool gefunden;
  final bool neu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 144,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeciesIllustration(
                  species: species,
                  size: 96,
                  iconSize: 72,
                  silhouette: !gefunden,
                  iconColor: gefunden ? AppColors.ink : AppColors.n400,
                ),
                const SizedBox(height: AppSpacing.x2),
                if (!gefunden)
                  Text(
                    'Noch nicht entdeckt',
                    key: const ValueKey('sheet-buehne-offen'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  )
                else if (neu)
                  Text(
                    'Neu in eurer Sammlung',
                    key: const ValueKey('sheet-buehne-neu'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              key: const ValueKey('sheet-schliessen'),
              tooltip: 'Schließen',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const PhosphorIcon(PhosphorIcons.x, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seltenheit, Artengruppe, Name, wissenschaftlicher Name.
class _Kopf extends StatelessWidget {
  const _Kopf({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teile = <String>[
      if (species.seltenheit.isNotEmpty)
        seltenheitEintrag(species.seltenheit).label,
      if (species.gruppe.isNotEmpty) gruppeEintrag(species.gruppe).label,
      if (species.isGeraet) species.kategorieLabel,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (teile.isNotEmpty)
          Text(
            teile.join(' · '),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        Text(species.nameDe, style: theme.textTheme.headlineSmall),
        if (species.nameLat.isNotEmpty)
          Text(
            species.nameLat,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.inkMuted,
            ),
          ),
      ],
    );
  }
}

/// Anhören (nur mit Audio) und im offenen Zustand „Hab ich gesehen“.
class _Aktionen extends StatelessWidget {
  const _Aktionen({
    required this.species,
    required this.gefunden,
    required this.onFreischalten,
  });

  final Species species;
  final bool gefunden;
  final VoidCallback onFreischalten;

  @override
  Widget build(BuildContext context) {
    final audio = species.hasPlayableAudio;
    if (!audio && gefunden) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stack),
      child: Wrap(
        spacing: AppSpacing.x2,
        runSpacing: AppSpacing.x2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (!gefunden)
            FilledButton.icon(
              key: const ValueKey('sheet-hab-ich-gesehen'),
              onPressed: onFreischalten,
              icon: const PhosphorIcon(PhosphorIcons.eye, size: 20),
              label: const Text('Hab ich gesehen'),
            ),
          if (audio)
            AudioPlayerControl(
              assetPath: species.audioPath!,
              playLabel: 'Anhören',
            ),
        ],
      ),
    );
  }
}

/// Gefunden: Zeitpunkt + Pfad. Offen: Pfade mit Anfahrt. Ohne Daten weg.
class _Kontext extends ConsumerWidget {
  const _Kontext({required this.species, required this.fund});

  final Species species;
  final Fund? fund;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = fund;

    if (f != null) {
      final wann = f.entdecktAm;
      if (wann == null) return const SizedBox.shrink();
      final pfad = f.trailId == null
          ? null
          : ref.watch(trailNamenProvider)[f.trailId];
      final text = [
        'Entdeckt ${relativeZeit(wann, DateTime.now())}',
        ?pfad,
      ].join(' · ');
      return Text(
        text,
        key: const ValueKey('sheet-kontext'),
        style: theme.textTheme.bodyMedium,
      );
    }

    final chancen = ref.watch(chancenFuerProvider(species.id)).take(3).toList();
    if (chancen.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('sheet-kontext'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpeciesSectionTitle(title: 'Gute Chancen'),
        const SizedBox(height: AppSpacing.afterHeading),
        for (final c in chancen)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              c.minuten == null
                  ? c.trail.name
                  : '${c.trail.name} · ${formatAnfahrt(c.minuten!)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// Einfachauswahl, optional. Erneuter Tap auf die aktive Option hebt auf.
class _Wer extends StatelessWidget {
  const _Wer({required this.von, required this.onChanged});

  final EntdecktVon? von;
  final ValueChanged<EntdecktVon?> onChanged;

  static const _labels = {
    EntdecktVon.erwachsene: 'Erwachsene',
    EntdecktVon.kind: 'Kind',
    EntdecktVon.gemeinsam: 'Gemeinsam',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpeciesSectionTitle(title: 'Wer hat’s entdeckt?'),
        const SizedBox(height: AppSpacing.afterHeading),
        Wrap(
          spacing: AppSpacing.chip,
          children: [
            for (final v in EntdecktVon.values)
              ChoiceChip(
                key: ValueKey('sheet-wer-${v.name}'),
                label: Text(_labels[v]!),
                selected: von == v,
                onSelected: (_) => onChanged(von == v ? null : v),
              ),
          ],
        ),
      ],
    );
  }
}

/// Textlink mit Inline-Bestätigung, kein Dialog.
class _Entfernen extends StatelessWidget {
  const _Entfernen({
    required this.frage,
    required this.onFrage,
    required this.onEntfernen,
  });

  final bool frage;
  final ValueChanged<bool> onFrage;
  final VoidCallback onEntfernen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!frage) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          key: const ValueKey('sheet-entfernen-link'),
          onPressed: () => onFrage(true),
          child: const Text('Doch nicht gesehen? Aus der Sammlung nehmen'),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text('Wirklich entfernen?', style: theme.textTheme.bodyMedium),
        ),
        TextButton(
          key: const ValueKey('sheet-entfernen-behalten'),
          onPressed: () => onFrage(false),
          child: const Text('Behalten'),
        ),
        TextButton(
          key: const ValueKey('sheet-entfernen-ja'),
          onPressed: onEntfernen,
          child: const Text('Entfernen'),
        ),
      ],
    );
  }
}
