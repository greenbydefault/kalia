import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../core/config/supabase_config.dart';
import 'sync_lifecycle.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/auth/presentation/account_tab.dart';
import '../features/auth/presentation/saved_list_prompt_host.dart';
import '../features/community/presentation/upload_snackbar_listener.dart';
import '../features/erkunden/erkunden_screen.dart';
import '../features/nearby_trails/data/karte_state.dart';
import '../features/nearby_trails/domain/karte_copy.dart';
import '../features/nearby_trails/presentation/coach_mark_overlay.dart';
import '../features/player/presentation/mini_player.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/onboarding/data/onboarding_prefs_provider.dart';
import '../features/species/presentation/species_collection_screen.dart';
import '../features/trail/presentation/map/map_screen.dart';
import '../features/trail_progress/presentation/my_routes_screen.dart';
import '../features/report/data/report_uploader.dart';
import '../features/report/presentation/report_banner.dart';
import 'shell_tab_provider.dart';
import 'theme/app_colors.dart';

/// Root-Shell: Karte · Erkunden · Meine Listen · Sammlung · Konto.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync-Lebenszyklus aktivieren (Queue-Flush, Login-Merge).
    ref.watch(syncLifecycleProvider);
    ref.watch(reportUploadLifecycleProvider);
    final completed = ref.watch(onboardingCompletedProvider);
    if (!completed.hasValue && !completed.hasError) {
      return const Scaffold(backgroundColor: AppColors.paper);
    }

    if (completed.value != true) return const OnboardingFlow();

    final index = ref.watch(shellTabIndexProvider);
    final loggedIn =
        SupabaseConfig.isConfigured &&
        ref.watch(authStateProvider).value != null;

    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: index,
                children: const [
                  MapScreen(),
                  ErkundenScreen(),
                  MyRoutesScreen(),
                  SpeciesCollectionScreen(),
                  AccountTab(),
                ],
              ),
              if (SupabaseConfig.isConfigured) const UploadSnackbarListener(),
              const MiniPlayerHost(),
              const SavedListPromptHost(),
              const ReportRecoveryHost(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              // Erneut auf „Karte“: Liste nach oben, ganz → halb.
              if (i == 0 && index == 0) {
                ref.read(karteRetapProvider.notifier).trigger();
              }
              ref.read(shellTabIndexProvider.notifier).goTo(i);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map),
                label: kt('nav.karte'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore),
                label: kt('nav.erkunden'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.bookmark_border),
                selectedIcon: const Icon(Icons.bookmark),
                label: kt('nav.listen'),
              ),
              NavigationDestination(
                icon: PhosphorIcon(PhosphorIcons.stack, size: 24),
                selectedIcon: PhosphorIcon(PhosphorIcons.stack, size: 24),
                label: kt('nav.sammlung'),
              ),
              NavigationDestination(
                icon: Icon(
                  loggedIn
                      ? Icons.account_circle_outlined
                      : Icons.person_outline,
                ),
                selectedIcon: Icon(
                  loggedIn ? Icons.account_circle : Icons.person,
                ),
                label: kt('nav.konto'),
              ),
            ],
          ),
        ),
        const CoachMarkHost(),
      ],
    );
  }
}
