import 'package:flutter/material.dart';

/// Design-Tokens der App. Einzige Stelle für Font-Familien.
///
/// Headlines (display/headline/title) nutzen [headlineFamily].
/// Body/Label bleiben die Plattform-Sans — Call-Sites rühren
/// `fontFamily` nicht an.
abstract final class AppTypography {
  static const headlineFamily = 'League Gothic';

  static TextTheme applyHeadlines(TextTheme base) {
    TextStyle? heading(TextStyle? s) =>
        s?.copyWith(fontFamily: headlineFamily, fontWeight: FontWeight.w400);
    return base.copyWith(
      displayLarge: heading(base.displayLarge),
      displayMedium: heading(base.displayMedium),
      displaySmall: heading(base.displaySmall),
      headlineLarge: heading(base.headlineLarge),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
      titleMedium: heading(base.titleMedium),
      titleSmall: heading(base.titleSmall),
    );
  }
}
