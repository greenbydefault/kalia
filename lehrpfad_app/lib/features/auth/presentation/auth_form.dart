import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/auth_providers.dart';
import '../data/pending_login.dart';

final _privacyUrl = Uri.parse('https://kalia-six.vercel.app/datenschutz');

/// Passwortlose Anmeldung — Konto-Tab, Login-Screen und Konto-Sheet.
/// Schritt 1 E-Mail, Schritt 2 Code. Neue und bestehende Konten laufen
/// gleich, Supabase legt das Konto beim ersten Code an.
class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({
    super.key,
    this.showHeadline = true,
    this.belowActions,
    this.onSuccess,
  });

  final bool showHeadline;
  final Widget? belowActions;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm>
    with WidgetsBindingObserver {
  static const _codeLength = 6;
  static const _resendCooldown = 60;
  static final _codePattern = RegExp(r'^\d{6}$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  String? _pendingEmail;
  bool _isLoading = false;
  String? _errorMessage;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String? _clipboardAtSend;

  bool get _inCodeStep => _pendingEmail != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restorePending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _inCodeStep) {
      _tryClipboard();
    }
  }

  Future<void> _restorePending() async {
    final pending = await PendingLogin.load();
    if (pending == null || !mounted) return;
    final elapsed = DateTime.now().difference(pending.sentAt).inSeconds;
    setState(() {
      _pendingEmail = pending.email;
      _emailController.text = pending.email;
    });
    _startCooldown(_resendCooldown - elapsed);
    unawaited(_tryClipboard());
  }

  Future<String> _readClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim() ?? '';
  }

  /// Ein alter Code in der Zwischenablage (vor dem Senden kopiert) wird
  /// ignoriert, sonst schlägt er beim Zurückkehren direkt fehl.
  Future<void> _tryClipboard() async {
    if (_isLoading) return;
    final text = await _readClipboard();
    if (!mounted || !_inCodeStep || !_codePattern.hasMatch(text)) return;
    if (text == _clipboardAtSend || text == _codeController.text) return;
    _clipboardAtSend = text;
    _codeController.text = text;
    unawaited(_verify());
  }

  void _startCooldown(int seconds) {
    _resendTimer?.cancel();
    if (seconds <= 0) {
      setState(() => _resendSeconds = 0);
      return;
    }
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim().toLowerCase();
    final ok = await _run(
      () => ref.read(authControllerProvider.notifier).sendCode(email),
    );
    if (!ok || !mounted) return;
    await PendingLogin.save(email);
    _clipboardAtSend = await _readClipboard();
    if (!mounted) return;
    setState(() {
      _pendingEmail = email;
      _codeController.clear();
    });
    _startCooldown(_resendCooldown);
    _codeFocus.requestFocus();
  }

  Future<void> _resend() async {
    final email = _pendingEmail;
    if (email == null) return;
    final ok = await _run(
      () => ref.read(authControllerProvider.notifier).sendCode(email),
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await PendingLogin.save(email);
    _clipboardAtSend = await _readClipboard();
    if (!mounted) return;
    _codeController.clear();
    _startCooldown(_resendCooldown);
    messenger?.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Neuer Code ist unterwegs.'),
      ),
    );
  }

  Future<void> _verify() async {
    final email = _pendingEmail;
    final code = _codeController.text.trim();
    if (email == null || code.length != _codeLength || _isLoading) return;
    final ok = await _run(
      () => ref
          .read(authControllerProvider.notifier)
          .verifyCode(email: email, code: code),
    );
    if (!mounted) return;
    if (!ok) {
      _codeController.clear();
      _codeFocus.requestFocus();
      return;
    }
    await PendingLogin.clear();
    widget.onSuccess?.call();
  }

  Future<void> _changeEmail() async {
    await PendingLogin.clear();
    _resendTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _pendingEmail = null;
      _errorMessage = null;
      _resendSeconds = 0;
      _codeController.clear();
    });
  }

  /// Führt [action] mit Spinner aus. `false` bei Fehler, Meldung steht dann.
  Future<bool> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapAuthError(e));
      return false;
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Keine Verbindung. Bitte gleich nochmal versuchen.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return 'Keine Verbindung. Bitte gleich nochmal versuchen.';
    }
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == 'over_email_send_rate_limit' ||
        e.statusCode == '429' ||
        msg.contains('rate limit') ||
        msg.contains('security purposes')) {
      return 'Gerade zu viele Codes. Bitte in ein paar Minuten nochmal.';
    }
    if (code == 'otp_expired' ||
        msg.contains('expired') ||
        (_inCodeStep && msg.contains('invalid'))) {
      return 'Code stimmt nicht oder ist abgelaufen.';
    }
    if (code == 'email_address_invalid' || msg.contains('email')) {
      return 'Bitte eine gültige E-Mail-Adresse eingeben.';
    }
    return 'Etwas ist schiefgelaufen. Bitte nochmal versuchen.';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._inCodeStep ? _codeStep(context) : _emailStep(context),
          if (widget.belowActions != null) widget.belowActions!,
        ],
      ),
    );
  }

  List<Widget> _emailStep(BuildContext context) {
    final theme = Theme.of(context);
    return [
      if (widget.showHeadline) ...[
        Text('Anmelden', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.x1),
        Text(
          'Die App funktioniert ohne Konto. Mit Konto könnt ihr Fotos '
          'hochladen, bewerten, kommentieren und eure Merkliste auf '
          'mehreren Geräten behalten.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x4),
      ],
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.go,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.email],
        onFieldSubmitted: (_) => _isLoading ? null : _sendCode(),
        decoration: const InputDecoration(
          labelText: 'E-Mail',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          final v = value?.trim() ?? '';
          if (v.isEmpty || !v.contains('@') || !v.contains('.')) {
            return 'Bitte eine gültige E-Mail-Adresse eingeben.';
          }
          return null;
        },
      ),
      ..._error(theme),
      const SizedBox(height: AppSpacing.x4),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _isLoading ? null : _sendCode,
        child: _isLoading ? const _Spinner() : const Text('Weiter'),
      ),
      const SizedBox(height: AppSpacing.x2),
      Text(
        'Wir schicken euch einen Code. Kein Passwort nötig.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
      TextButton(
        onPressed: () =>
            launchUrl(_privacyUrl, mode: LaunchMode.externalApplication),
        child: const Text('Datenschutz'),
      ),
    ];
  }

  List<Widget> _codeStep(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text('Code eingeben', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.x1),
      Text.rich(
        TextSpan(
          text: 'Wir haben einen 6-stelligen Code an ',
          children: [
            TextSpan(
              text: _pendingEmail,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' geschickt.'),
          ],
        ),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.x4),
      TextField(
        controller: _codeController,
        focusNode: _codeFocus,
        autofocus: true,
        enabled: !_isLoading,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: _codeLength,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: theme.textTheme.headlineMedium?.copyWith(
          letterSpacing: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: const InputDecoration(
          hintText: '000000',
          counterText: '',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          if (v.length == _codeLength) _verify();
        },
      ),
      ..._error(theme),
      if (_isLoading) ...[
        const SizedBox(height: AppSpacing.x3),
        const Center(child: _Spinner()),
      ],
      const SizedBox(height: AppSpacing.x3),
      Text(
        'Nichts da? Schaut im Spam-Ordner.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.x2),
      TextButton(
        onPressed: _isLoading || _resendSeconds > 0 ? null : _resend,
        child: Text(
          _resendSeconds > 0
              ? 'Code erneut senden ($_resendSeconds s)'
              : 'Code erneut senden',
        ),
      ),
      TextButton(
        onPressed: _isLoading ? null : _changeEmail,
        child: const Text('Andere E-Mail?'),
      ),
    ];
  }

  List<Widget> _error(ThemeData theme) => [
    if (_errorMessage != null) ...[
      const SizedBox(height: AppSpacing.x3),
      Text(
        _errorMessage!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ],
  ];
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
