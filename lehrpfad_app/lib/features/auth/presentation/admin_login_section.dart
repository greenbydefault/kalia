import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/admin_credentials.dart';
import '../data/auth_providers.dart';

/// Kompakter Admin-Login. Testdaten nur in Debug vorausgefüllt.
class AdminLoginSection extends ConsumerStatefulWidget {
  const AdminLoginSection({super.key});

  @override
  ConsumerState<AdminLoginSection> createState() => _AdminLoginSectionState();
}

class _AdminLoginSectionState extends ConsumerState<AdminLoginSection> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: AdminCredentials.email);
    _passwordController = TextEditingController(
      text: AdminCredentials.password,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      await auth.signIn(email: email, password: password);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        try {
          await auth.signUp(
            email: email,
            password: password,
            displayName: 'Admin',
          );
          await auth.signIn(email: email, password: password);
        } on AuthException catch (e2) {
          final msg2 = e2.message.toLowerCase();
          setState(() {
            if (msg2.contains('already')) {
              _errorMessage = 'E-Mail oder Passwort falsch.';
            } else if (msg2.contains('not confirmed')) {
              _errorMessage =
                  'Bitte zuerst die E-Mail bestätigen, dann erneut anmelden.';
            } else {
              _errorMessage = 'Login fehlgeschlagen.';
            }
          });
        }
      } else if (msg.contains('not confirmed')) {
        setState(
          () => _errorMessage =
              'Bitte zuerst die E-Mail bestätigen, dann erneut anmelden.',
        );
      } else {
        setState(() => _errorMessage = 'Login fehlgeschlagen.');
      }
    } catch (_) {
      setState(() => _errorMessage = 'Keine Verbindung zum Server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Admin', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Moderation der hochgeladenen Bilder.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            labelText: 'E-Mail',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          enabled: !_isLoading,
          decoration: InputDecoration(
            labelText: 'Passwort',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Als Admin anmelden'),
        ),
      ],
    );
  }
}
