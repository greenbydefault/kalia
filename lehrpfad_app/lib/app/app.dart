import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

class LehrpfadApp extends StatelessWidget {
  const LehrpfadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lehrpfade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
