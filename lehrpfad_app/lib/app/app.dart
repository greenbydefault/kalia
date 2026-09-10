import 'package:flutter/material.dart';

import '../shared/scrolling/smooth_scroll.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';

class LehrpfadApp extends StatelessWidget {
  const LehrpfadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const SmoothScrollBehavior(),
      home: const AppShell(),
    );
  }
}
