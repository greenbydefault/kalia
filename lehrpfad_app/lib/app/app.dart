import 'package:flutter/material.dart';

import '../features/report/presentation/report_banner.dart';
import '../shared/scrolling/smooth_scroll.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';

class LehrpfadApp extends StatelessWidget {
  const LehrpfadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalia',
      navigatorKey: reportNavigatorKey,
      builder: (context, child) =>
          RecordingBannerHost(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const SmoothScrollBehavior(),
      home: const AppShell(),
    );
  }
}
