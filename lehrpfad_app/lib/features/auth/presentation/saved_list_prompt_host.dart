import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../trail_progress/presentation/quick_merken.dart';
import '../data/auth_providers.dart';
import 'account_prompt_sheet.dart';

/// Ab dieser Zahl gemerkter Pfade kommt einmal das Konto-Sheet.
const accountPromptThreshold = 10;

final accountPromptThresholdProvider = Provider<int>(
  (ref) => accountPromptThreshold,
);

/// Hört auf die Merkliste und zeigt das Konto-Sheet genau einmal, wenn die
/// Schwelle erreicht wird. Ohne Konto bleibt alles nutzbar.
class SavedListPromptHost extends ConsumerWidget {
  const SavedListPromptHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int?>(savedTrailCountProvider, (prev, next) {
      if (prev == null || next == null || next <= prev) return;
      if (next < ref.read(accountPromptThresholdProvider)) return;
      if (!SupabaseConfig.isConfigured) return;
      if (ref.read(authStateProvider).value != null) return;
      final prefs = ref.read(onboardingPrefsProvider).asData?.value;
      if (prefs == null || prefs.accountPromptSeen) return;

      ref.read(onboardingPrefsProvider.notifier).markAccountPromptSeen();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showSavedListSheet(context);
      });
    });
    return const SizedBox.shrink();
  }
}
