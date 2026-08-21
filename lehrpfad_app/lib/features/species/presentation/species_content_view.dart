import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/audio/audio_player_control.dart';
import '../domain/species.dart';

/// Abschnitte des Outdoor-Steckbriefs (Hook, Erkennung, …).
class SpeciesContentView extends StatelessWidget {
  const SpeciesContentView({super.key, required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = species.content;
    final hook = species.displayHook;
    final audioPath = species.audioPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hook.isNotEmpty) ...[
          Text(
            hook,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (c.erkennung.isNotEmpty) ...[
          _SectionTitle(theme: theme, title: 'Woran erkenne ich’s?'),
          const SizedBox(height: 8),
          ...c.erkennung.map((b) => _Bullet(theme: theme, text: b)),
          const SizedBox(height: 16),
        ],
        if (c.lebensraum.isNotEmpty) ...[
          _SectionTitle(theme: theme, title: 'Hier unterwegs'),
          const SizedBox(height: 8),
          Text(c.lebensraum, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        if (c.funFacts.isNotEmpty) ...[
          _SectionTitle(theme: theme, title: 'Fun Facts'),
          const SizedBox(height: 8),
          ...c.funFacts.map((b) => _Bullet(theme: theme, text: b)),
          const SizedBox(height: 16),
        ],
        if (c.hinweis.trim().isNotEmpty) ...[
          Text(
            c.hinweis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (audioPath != null && audioPath.isNotEmpty) ...[
          AudioPlayerControl(assetPath: audioPath),
          const SizedBox(height: 16),
        ],
        if (c.hoertext.trim().isNotEmpty) ...[
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'Text zum Vorlesen',
                style: theme.textTheme.titleSmall,
              ),
              children: [
                Text(
                  c.hoertext,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.theme, required this.title});

  final ThemeData theme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: theme.textTheme.titleSmall);
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.theme, required this.text});

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('·  ', style: theme.textTheme.bodyMedium),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
