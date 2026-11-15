import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../community/data/community_providers.dart';
import '../data/auth_providers.dart';

/// Fragt den öffentlichen Namen ab, wenn noch keiner gesetzt ist.
/// `true`, wenn danach ein Name da ist.
Future<bool> ensureDisplayName(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final user = container.read(authStateProvider).value;
  if (user == null) return false;
  final profile = await container.read(currentProfileProvider.future);
  if (!isDisplayNameUnset(profile?.displayName ?? '', user.email)) {
    return true;
  }
  if (!context.mounted) return false;
  final saved = await showAppModalSheet<bool>(
    context: context,
    padForKeyboard: true,
    builder: (_) => const _DisplayNameSheet(),
  );
  return saved ?? false;
}

/// Speichert [name] als Anzeigenamen, wenn noch keiner gesetzt ist.
Future<void> adoptDisplayNameIfUnset(WidgetRef ref, String name) async {
  final trimmed = name.trim();
  final user = ref.read(authStateProvider).value;
  final repo = ref.read(profilesRepositoryProvider);
  if (trimmed.isEmpty || user == null || repo == null) return;
  final profile = await ref.read(currentProfileProvider.future);
  if (!isDisplayNameUnset(profile?.displayName ?? '', user.email)) return;
  await repo.updateDisplayName(user.id, trimmed);
  ref.invalidate(currentProfileProvider);
}

class _DisplayNameSheet extends ConsumerStatefulWidget {
  const _DisplayNameSheet();

  @override
  ConsumerState<_DisplayNameSheet> createState() => _DisplayNameSheetState();
}

class _DisplayNameSheetState extends ConsumerState<_DisplayNameSheet> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    final user = ref.read(authStateProvider).value;
    final repo = ref.read(profilesRepositoryProvider);
    if (name.isEmpty || user == null || repo == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repo.updateDisplayName(user.id, name);
      ref.invalidate(currentProfileProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Speichern hat nicht geklappt. Bitte nochmal versuchen.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Wie sollen wir euch nennen?',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Der Name steht an euren Kommentaren und Fotos.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x4),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saving ? null : _save(),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Name, z. B. Familie Müller',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _saving || _controller.text.trim().isEmpty ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
