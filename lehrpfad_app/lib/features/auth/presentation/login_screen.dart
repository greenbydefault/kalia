import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import 'auth_form.dart';

/// Vollbild-Login (bestehender [AuthForm]) für „Ich habe schon ein Konto“.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: AuthForm(onSuccess: () => Navigator.of(context).pop(true)),
        ),
      ),
    );
  }
}
