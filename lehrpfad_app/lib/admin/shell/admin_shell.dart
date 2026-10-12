import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../features/community/data/community_providers.dart';
import '../auth/admin_session.dart';
import '../collections/registry.dart';
import '../core/admin_repository.dart';

/// Rahmen: links der Katalog (Ordner mit Anzahl), rechts der Inhalt.
/// Unter 900 px wird die Sidebar zum Drawer.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.session,
    required this.location,
    required this.child,
  });

  final AdminSession session;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final sidebar = _Sidebar(session: session, location: location);
        if (c.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 232, child: sidebar),
                const VerticalDivider(width: 1, color: AppColors.n200),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kalia Admin'),
            scrolledUnderElevation: 0,
          ),
          drawer: Drawer(child: sidebar),
          body: child,
        );
      },
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.session, required this.location});

  final AdminSession session;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pending = ref.watch(pendingImagesProvider).value?.length ?? 0;
    return ColoredBox(
      color: AppColors.n100,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Kalia Admin', style: theme.textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final spec in adminCollections)
                    _NavItem(
                      icon: spec.icon,
                      label: spec.label,
                      selected:
                          location == spec.path ||
                          location.startsWith('${spec.path}/'),
                      count: ref.watch(collectionCountProvider(spec)).value,
                      onTap: () => _go(context, spec.path),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Divider(height: 1, color: AppColors.n300),
                  ),
                  _NavItem(
                    icon: moderationSection.icon,
                    label: moderationSection.label,
                    selected: location.startsWith('/${moderationSection.id}'),
                    count: pending > 0 ? pending : null,
                    highlight: pending > 0,
                    onTap: () => _go(context, '/${moderationSection.id}'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.n300),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      session.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Abmelden',
                    icon: const Icon(Icons.logout, size: 18),
                    onPressed: session.signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String path) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) Navigator.of(context).pop();
    context.go(path);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int? count;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? AppColors.n200 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: highlight
                        ? BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    child: Text(
                      '$count',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: highlight ? AppColors.n50 : AppColors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
