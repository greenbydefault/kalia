import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/app_colors.dart';
import 'admin_session.dart';

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({required this.title, required this.children, this.footer});

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kalia Admin', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 24),
                ...children,
                if (footer != null) ...[const SizedBox(height: 16), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _authError(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'E-Mail oder Passwort falsch.';
    if (m.contains('invalid') && m.contains('code')) return 'Code falsch.';
    return e.message;
  }
  return 'Das hat nicht geklappt.';
}

/// E-Mail + Passwort. Kein Signup, keine Vorbelegung.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, required this.session});

  final AdminSession session;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.signIn(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Anmelden',
      children: [
        TextField(
          controller: _email,
          autofocus: true,
          autofillHints: const [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-Mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Passwort'),
          onSubmitted: (_) => _busy ? null : _submit(),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Anmelden'),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.error),
    ),
  );
}

/// Eingeloggt, aber kein Admin.
class AdminDeniedPage extends StatelessWidget {
  const AdminDeniedPage({super.key, required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Kein Zugriff',
      children: [
        Text('${session.email ?? 'Dieses Konto'} ist kein Admin.'),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: session.signOut,
          child: const Text('Abmelden'),
        ),
      ],
    );
  }
}

/// Zweiter Faktor: einrichten (QR) oder Code eingeben.
class AdminMfaPage extends StatefulWidget {
  const AdminMfaPage({super.key, required this.session, required this.enroll});

  final AdminSession session;
  final bool enroll;

  @override
  State<AdminMfaPage> createState() => _AdminMfaPageState();
}

class _AdminMfaPageState extends State<AdminMfaPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _factorId;
  String? _qrSvg;
  String? _secret;

  GoTrueMFAApi get _mfa => Supabase.instance.client.auth.mfa;

  @override
  void initState() {
    super.initState();
    if (widget.enroll) _startEnroll();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _startEnroll() async {
    setState(() => _busy = true);
    try {
      // Abgebrochene Versuche blockieren sonst den Namen.
      final user = Supabase.instance.client.auth.currentUser;
      for (final f in user?.factors ?? const <Factor>[]) {
        if (f.status == FactorStatus.unverified) {
          await _mfa.unenroll(f.id);
        }
      }
      final res = await _mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'Kalia Admin',
        friendlyName: 'Authenticator ${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() {
        _factorId = res.id;
        _qrSvg = res.totp?.qrCode;
        _secret = res.totp?.secret;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var factorId = _factorId;
      if (factorId == null) {
        final list = await _mfa.listFactors();
        if (list.totp.isEmpty) throw StateError('Kein Faktor');
        factorId = list.totp.first.id;
      }
      await _mfa.challengeAndVerify(factorId: factorId, code: code);
      await widget.session.refresh();
    } catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _AuthFrame(
      title: widget.enroll
          ? 'Zweiten Faktor einrichten'
          : 'Code aus der Authenticator-App',
      footer: TextButton(
        onPressed: widget.session.signOut,
        child: const Text('Abmelden'),
      ),
      children: [
        if (widget.enroll) ...[
          if (_qrSvg != null) ...[
            Center(child: SvgPicture.string(_qrSvg!, width: 180, height: 180)),
            const SizedBox(height: 8),
            SelectableText(
              _secret ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_busy)
            const Center(child: CircularProgressIndicator())
          else
            OutlinedButton(
              onPressed: _startEnroll,
              child: const Text('Erneut versuchen'),
            ),
        ],
        TextField(
          controller: _code,
          autofocus: !widget.enroll,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '6-stelliger Code',
            counterText: '',
          ),
          onSubmitted: (_) => _busy ? null : _verify(),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || (widget.enroll && _factorId == null)
              ? null
              : _verify,
          child: Text(widget.enroll ? 'Bestätigen' : 'Weiter'),
        ),
      ],
    );
  }
}
