import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/motion/reduced_motion.dart';
import '../../../../shared/widgets/lowpoly_placeholder_scene.dart';
import '../../../auth/presentation/login_screen.dart';

/// Screen 1: Willkommen. Kein Konto, keine Fragen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.onLoggedIn,
  });

  final VoidCallback onStart;
  final VoidCallback onLoggedIn;

  static const headline = 'Kleine Wege. Große Entdeckungen.';
  static const subline =
      'Lehrpfade, Moore und Wasserspielplätze für Familien in ganz '
      'Deutschland. Ohne Anmeldung.';

  Future<void> _openLogin(BuildContext context) async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (ok == true) onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;
    final textDelay = context.motion(const Duration(milliseconds: 900));

    final items = <Widget>[
      Text(headline, style: theme.textTheme.displaySmall),
      const SizedBox(height: AppSpacing.x3),
      Text(
        subline,
        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
      ),
      const SizedBox(height: AppSpacing.x6),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: onStart,
        child: const Text('Los geht’s'),
      ),
      const SizedBox(height: AppSpacing.x1),
      if (SupabaseConfig.isConfigured)
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => _openLogin(context),
          child: const Text('Ich habe schon ein Konto'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: height * 0.5, child: const LowpolyPlaceholderScene()),
        Expanded(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x6,
                AppSpacing.x6,
                AppSpacing.x6,
                AppSpacing.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items
                    .animate(
                      delay: textDelay,
                      interval: context.motion(OnboardingMotion.textStagger),
                    )
                    .fadeIn(
                      duration: context.motion(OnboardingMotion.sceneLayer),
                      curve: Curves.easeOutCubic,
                    )
                    .moveY(
                      begin: 18,
                      end: 0,
                      duration: context.motion(OnboardingMotion.sceneLayer),
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
