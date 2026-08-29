import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_providers.dart';

/// E-Mail/Passwort Login und Registrierung — Konto-Tab und Onboarding.
class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({
    super.key,
    this.initialDisplayName,
    this.startInRegisterMode = false,
    this.showHeadline = true,
    this.aboveFields,
    this.belowActions,
    this.onSuccess,
  });

  final String? initialDisplayName;
  final bool startInRegisterMode;
  final bool showHeadline;
  final Widget? aboveFields;
  final Widget? belowActions;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TextEditingController _nameController;

  late bool _isRegisterMode;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.startInRegisterMode;
    _nameController = TextEditingController(
      text: widget.initialDisplayName ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final typedName = _nameController.text.trim();
    final displayName = typedName.isNotEmpty
        ? typedName
        : widget.initialDisplayName?.trim();

    try {
      if (_isRegisterMode) {
        await auth.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
      } else {
        await auth.signIn(email: email, password: password);
      }
      widget.onSuccess?.call();
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e));
    } catch (_) {
      setState(
        () => _errorMessage =
            'Keine Verbindung zum Server. Bitte später erneut versuchen.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-Mail oder Passwort falsch.';
    }
    if (msg.contains('user already registered')) {
      return 'Diese E-Mail ist bereits registriert.';
    }
    if (msg.contains('password')) {
      return 'Das Passwort ist zu schwach (mind. 6 Zeichen).';
    }
    if (msg.contains('email')) {
      return 'Bitte eine gültige E-Mail-Adresse eingeben.';
    }
    return 'Etwas ist schiefgelaufen. Bitte erneut versuchen.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeadline) ...[
            Text(
              _isRegisterMode ? 'Konto erstellen' : 'Anmelden',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Mit einem Konto kannst du Strecken bewerten und kommentieren. '
              'Fotos hochladen geht auch ohne Anmeldung.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.aboveFields != null) ...[
            widget.aboveFields!,
            const SizedBox(height: 16),
          ],
          if (_isRegisterMode) ...[
            TextFormField(
              controller: _nameController,
              autocorrect: false,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Anzeigename (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-Mail',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty || !v.contains('@')) {
                return 'Bitte eine gültige E-Mail-Adresse eingeben.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: _isRegisterMode
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
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
            validator: (value) {
              if ((value?.length ?? 0) < 6) {
                return 'Mind. 6 Zeichen.';
              }
              return null;
            },
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isRegisterMode ? 'Registrieren' : 'Anmelden'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _errorMessage = null;
                  }),
            child: Text(
              _isRegisterMode
                  ? 'Schon ein Konto? Anmelden'
                  : 'Noch kein Konto? Registrieren',
            ),
          ),
          if (widget.belowActions != null) widget.belowActions!,
        ],
      ),
    );
  }
}
