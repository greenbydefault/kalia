import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/show_app_modal_sheet.dart';
import '../../domain/external_navigation.dart';
import '../../domain/trail.dart';

/// Auswahl einer externen Karten-App für die Anreise.
class NavigationSheet extends StatelessWidget {
  const NavigationSheet({super.key, required this.trail});

  final Trail trail;

  static Future<void> show(BuildContext context, Trail trail) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => NavigationSheet(trail: trail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dest = navigationDestinationFor(trail);
    final subtitle = dest == null
        ? trail.startName
        : dest.isParking
        ? '${dest.label} · Parkplatz'
        : dest.label;
    final coords = dest == null ? null : formatLatLng(dest.position);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Navigation', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x1),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (coords != null) ...[
          const SizedBox(height: AppSpacing.x1),
          Text(
            coords,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x3),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const PhosphorIcon(PhosphorIcons.googleLogo, size: 22),
          title: const Text('Google Maps'),
          onTap: dest == null
              ? null
              : () => _open(context, MapProvider.googleMaps, dest),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const PhosphorIcon(PhosphorIcons.appleLogo, size: 22),
          title: const Text('Apple Karten'),
          onTap: dest == null
              ? null
              : () => _open(context, MapProvider.appleMaps, dest),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const PhosphorIcon(PhosphorIcons.mapTrifold, size: 22),
          title: const Text('OpenStreetMap'),
          onTap: dest == null
              ? null
              : () => _open(context, MapProvider.openStreetMap, dest),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const PhosphorIcon(PhosphorIcons.copySimple, size: 22),
          title: const Text('Adresse kopieren'),
          onTap: () => _copyAddress(context),
        ),
      ],
    );
  }

  Future<void> _open(
    BuildContext context,
    MapProvider provider,
    AnreiseDestination dest,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final uri = directionsUri(provider, dest.position);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Karte konnte nicht geöffnet werden.')),
    );
  }

  Future<void> _copyAddress(BuildContext context) async {
    final text = copyAddressLabel(trail);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kopiert')));
  }
}
