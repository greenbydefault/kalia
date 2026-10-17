import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/report_permission_service.dart';
import '../logic/permission_logic.dart';
import '../report_copy.dart';
import 'report_widgets.dart';

/// Prüft die Berechtigungen in der Reihenfolge von Spec 3.4. Fehlt etwas,
/// erscheint R14, sonst kehrt der Aufruf sofort mit `true` zurück.
Future<bool> ensureReportPermission(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final snap = await container.read(reportPermissionServiceProvider).snapshot();
  if (permissionGate(snap) == null) return true;
  if (!context.mounted) return false;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const ReportPermissionScreen()),
  );
  return ok ?? false;
}

/// R14 „Berechtigung erklären“, fünf Varianten. Beim Zurückkehren aus den
/// Einstellungen prüft der Screen erneut und geht von selbst weiter.
class ReportPermissionScreen extends ConsumerStatefulWidget {
  const ReportPermissionScreen({super.key});

  @override
  ConsumerState<ReportPermissionScreen> createState() =>
      _ReportPermissionScreenState();
}

class _ReportPermissionScreenState extends ConsumerState<ReportPermissionScreen>
    with WidgetsBindingObserver {
  PermVariant? _variant;
  bool _busy = false;

  ReportPermissionService get _service =>
      ref.read(reportPermissionServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final snap = await _service.snapshot();
    if (!mounted) return;
    final gate = permissionGate(snap);
    if (gate == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _variant = gate);
  }

  Future<void> _primary() async {
    final v = _variant;
    if (v == null || _busy) return;
    setState(() => _busy = true);
    try {
      switch (v) {
        case PermVariant.pre:
        case PermVariant.denied:
          await _service.requestPermission();
        case PermVariant.settings:
          await _service.openAppSettings();
        case PermVariant.off:
          await _service.openLocationSettings();
        case PermVariant.precise:
          await _service.requestPrecise();
          if (!await _service.snapshot().then((s) => s.precise)) {
            // iOS fragt einmal, Android nie: dann in die Einstellungen.
            await _service.openAppSettings();
          }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    final theme = Theme.of(context);
    if (v == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final key = switch (v) {
      PermVariant.pre => 'pre',
      PermVariant.denied => 'denied',
      PermVariant.settings => 'settings',
      PermVariant.off => 'off',
      PermVariant.precise => 'precise',
    };
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                v == PermVariant.precise
                    ? Icons.my_location
                    : Icons.location_on_outlined,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.section),
              Text(
                rt('report.perm.$key.title'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stack),
              Text(
                rt('report.perm.$key.body'),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ReportPrimaryButton(
                label: rt('report.perm.$key.cta'),
                loading: _busy,
                onPressed: _primary,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(rt('report.perm.later')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Einmal pro Installation (Android): Hinweis zur Akku-Optimierung vor dem
/// ersten Start der Aufnahme.
Future<void> maybeShowBatteryHint(BuildContext context) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  if (!await BatteryHintFlag.shouldShow()) return;
  await BatteryHintFlag.markShown();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(rt('report.perm.battery')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(rt('report.perm.battery.cta')),
        ),
      ],
    ),
  );
}
