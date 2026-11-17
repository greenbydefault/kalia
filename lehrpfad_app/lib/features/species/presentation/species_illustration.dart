import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../offline/offline.dart';
import '../domain/species.dart';

/// Lokaler Pfad einer per URL geladenen Illustration (Disk-Cache).
///
/// Der Cache hat Vorrang, auch offline. Die Dateinamen im Bucket tragen einen
/// Hash bzw. Zeitstempel, eine Änderung im CMS ist also immer eine neue URL.
/// Nur ohne Treffer wird geladen, und nur online. Kommt das Netz zurück,
/// läuft der Provider neu und holt Fehlendes nach.
final illustrationFileProvider = FutureProvider.family<String?, String>((
  ref,
  url,
) async {
  final online = ref.watch(isOnlineProvider);
  final cache = DefaultCacheManager();
  final hit = await cache.getFileFromCache(url);
  if (hit != null) return hit.file.path;
  if (!online) return null;
  try {
    return (await cache.getSingleFile(url)).path;
  } catch (_) {
    return null;
  }
});

/// Illustration einer Art (SVG aus dem CMS), sonst das Kategorie-Icon.
///
/// Ohne Illustration entsteht genau das alte Icon, ohne extra Box. Mit
/// Illustration reserviert [size] den Platz; bis zum Laden und bei Fehlern
/// steht dort das Icon, damit nichts springt. [silhouette] färbt die
/// Illustration einfarbig ab (noch nicht entdeckt), ohne zweites Asset.
class SpeciesIllustration extends ConsumerWidget {
  const SpeciesIllustration({
    super.key,
    required this.species,
    required this.size,
    required this.iconSize,
    this.silhouette = false,
    this.iconColor = AppColors.ink,
  });

  final Species species;

  /// Kantenlänge der Illustration (quadratische Box, Inhalt `contain`).
  final double size;

  /// Größe des Icons ohne Illustration bzw. als Platzhalter.
  final double iconSize;
  final bool silhouette;
  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = PhosphorIcon(
      species.displayIconEintrag.icon,
      size: iconSize,
      color: iconColor,
    );
    final path = species.illustrationPath;
    if (path == null || path.isEmpty) return icon;

    final resolved = ref
        .watch(assetResolverProvider)
        .illustration(IllustrationRef(path));

    Widget placeholder() => SizedBox(
      width: size,
      height: size,
      child: Center(child: icon),
    );

    final filter = silhouette
        ? const ColorFilter.mode(AppColors.n400, BlendMode.srcIn)
        : null;

    SvgPicture file(String p) => SvgPicture.file(
      File(p),
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: filter,
      placeholderBuilder: (_) => placeholder(),
      errorBuilder: (_, _, _) => placeholder(),
    );

    return switch (resolved) {
      null => placeholder(),
      IllustrationFile(:final path) => file(path),
      IllustrationAsset(:final path) => SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: filter,
        placeholderBuilder: (_) => placeholder(),
        errorBuilder: (_, _, _) => placeholder(),
      ),
      IllustrationUrl(:final url) when kIsWeb => SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: filter,
        placeholderBuilder: (_) => placeholder(),
        errorBuilder: (_, _, _) => placeholder(),
      ),
      IllustrationUrl(:final url) =>
        ref
            .watch(illustrationFileProvider(url))
            .when(
              data: (p) => p == null ? placeholder() : file(p),
              loading: placeholder,
              error: (_, _) => placeholder(),
            ),
    };
  }
}
