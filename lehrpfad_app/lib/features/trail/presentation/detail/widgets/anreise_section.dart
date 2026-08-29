import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../domain/trail.dart';
import '../navigation_sheet.dart';
import 'sheet_accordion_section.dart';

/// Accordion Anreise & Infos (Öffnungszeiten, Website, Navigation, Betreiber).
class AnreiseSection extends StatelessWidget {
  const AnreiseSection({super.key, required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetAccordionSection(
      title: 'Anreise & Infos',
      children: [
        if (trail.oeffnungszeiten != null &&
            trail.oeffnungszeiten!.isNotEmpty) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const PhosphorIcon(PhosphorIcons.clock, size: 22),
            title: const Text('Öffnungszeiten'),
            subtitle: Text(trail.oeffnungszeiten!),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        if (trail.eintrittPreise != null &&
            trail.eintrittPreise!.isNotEmpty) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: PhosphorIcon(
              trail.eintritt ? PhosphorIcons.ticket : PhosphorIcons.currencyEur,
              size: 22,
            ),
            title: Text(trail.eintritt ? 'Eintritt' : 'Preise'),
            subtitle: Text(trail.eintrittPreise!),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        if (trail.besuchshinweise != null &&
            trail.besuchshinweise!.isNotEmpty) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const PhosphorIcon(PhosphorIcons.info, size: 22),
            title: const Text('Vor dem Besuch'),
            subtitle: Text(trail.besuchshinweise!),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        if (trail.website != null && trail.website!.isNotEmpty) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const PhosphorIcon(PhosphorIcons.globe, size: 22),
            title: const Text('Website'),
            onTap: () => _openWebsite(trail.website!),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        Text(trail.anreise, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x3),
        if (trail.startOrNull != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => NavigationSheet.show(context, trail),
              icon: const PhosphorIcon(PhosphorIcons.navigationArrow, size: 18),
              label: const Text('Navigation starten'),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_balance_outlined),
          title: Text(trail.betreiber),
          subtitle: Text('Start: ${trail.startName}'),
        ),
      ],
    );
  }
}

Future<void> _openWebsite(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
