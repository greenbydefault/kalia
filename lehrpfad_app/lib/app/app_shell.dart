import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../core/config/supabase_config.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/auth/presentation/account_tab.dart';
import '../features/onboarding/data/onboarding_providers.dart';
import '../features/onboarding/presentation/onboarding_overlay.dart';
import '../features/species/presentation/species_collection_screen.dart';
import '../features/trail/presentation/map/map_screen.dart';
import '../features/trail_progress/presentation/my_routes_screen.dart';
import 'shell_tab_provider.dart';
import 'theme/app_colors.dart';

/// Root-Shell: Karte · Meine Listen · Arten · Konto.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(onboardingCompletedProvider);
    if (!completed.hasValue && !completed.hasError) {
      return const Scaffold(backgroundColor: AppColors.paper);
    }

    final onboarding = completed.value != true;
    final index = onboarding ? 0 : ref.watch(shellTabIndexProvider);
    final loggedIn =
        SupabaseConfig.isConfigured &&
        ref.watch(authStateProvider).value != null;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: const [
              MapScreen(),
              MyRoutesScreen(),
              SpeciesCollectionScreen(),
              AccountTab(),
            ],
          ),
          if (onboarding) const OnboardingOverlay(),
        ],
      ),
      bottomNavigationBar: onboarding
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) =>
                  ref.read(shellTabIndexProvider.notifier).goTo(i),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Karte',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.bookmark_border),
                  selectedIcon: Icon(Icons.bookmark),
                  label: 'Meine Listen',
                ),
                NavigationDestination(
                  icon: PhosphorIcon(PhosphorIcons.stack, size: 24),
                  selectedIcon: PhosphorIcon(PhosphorIcons.stack, size: 24),
                  label: 'Sammlung',
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
                  label: 'Konto',
                ),
              ],
            ),
    );
  }
}
