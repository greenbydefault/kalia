import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/build_stamp.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../trail_progress/tracking/location_service.dart';
import '../../data/onboarding_prefs_provider.dart';
import '../../data/place_search.dart';
import '../../domain/user_place.dart';
import '../widgets/step_header.dart';

/// Screen 3b: Ort eingeben. Auch standalone („Ort ändern“) nutzbar.
class PlaceScreen extends ConsumerStatefulWidget {
  const PlaceScreen({
    super.key,
    required this.onBack,
    required this.onDone,
    this.showSettingsHint = false,
    this.standalone = false,
  });

  final VoidCallback onBack;
  final VoidCallback onDone;
  final bool showSettingsHint;

  /// Ohne Fortschrittsanzeige (z. B. aus dem Karten-Panel geöffnet).
  final bool standalone;

  static const notFoundToast = 'Ort nicht gefunden, wir zeigen alle Wege.';

  @override
  ConsumerState<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends ConsumerState<PlaceScreen> {
  final _controller = TextEditingController();
  UserPlace? _selected;

  @override
  void initState() {
    super.initState();
    final place = ref.read(onboardingPrefsValueProvider).place;
    if (place != null) {
      _selected = place;
      _controller.text = place.label;
    }
    _controller.addListener(_onText);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onText)
      ..dispose();
    super.dispose();
  }

  void _onText() {
    if (_selected != null && _controller.text != _selected!.label) {
      _selected = null;
    }
    setState(() {});
  }

  List<UserPlace> _suggestions() {
    if (_selected != null) return const [];
    final index = ref.watch(placeIndexProvider).asData?.value;
    return index?.search(_controller.text) ?? const [];
  }

  bool get _canSubmit =>
      _selected != null ||
      _controller.text.trim().length >= PlaceIndex.minChars;

  void _pick(UserPlace place) {
    _selected = place;
    _controller.text = place.label;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  Future<void> _submit() async {
    markNearbyRequested();
    var place = _selected;
    if (place == null) {
      final index = ref.read(placeIndexProvider).asData?.value;
      final hits = index?.search(_controller.text) ?? const <UserPlace>[];
      if (hits.isNotEmpty) place = hits.first;
    }
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(PlaceScreen.notFoundToast),
        ),
      );
    } else {
      await ref.read(onboardingPrefsProvider.notifier).setPlace(place);
    }
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _suggestions();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.standalone)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Zurück',
                onPressed: widget.onBack,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const PhosphorIcon(PhosphorIcons.caretLeft, size: 24),
              ),
            )
          else
            OnboardingStepHeader(step: 2, onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Von wo startet ihr meistens?',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Ort oder Postleitzahl reicht. Ihr könnt das jederzeit '
                    'ändern.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  if (widget.showSettingsHint) ...[
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      'Der Standort ist für Kalia gesperrt. In den '
                      'Einstellungen lässt er sich wieder erlauben.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(locationServiceProvider)
                          .openSystemSettings(),
                      child: const Text('Einstellungen öffnen'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x5),
                  TextField(
                    controller: _controller,
                    autofocus: !widget.showSettingsHint,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    onSubmitted: (_) {
                      if (_canSubmit) _submit();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Ort oder Postleitzahl',
                      hintText: 'z. B. Leipzig oder 04109',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x2),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(AppSpacing.x3),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Column(
                        children: [
                          for (final p in suggestions)
                            InkWell(
                              onTap: () => _pick(p),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 52,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.x4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: theme.textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        p.plz,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppColors.inkMuted,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x2,
              AppSpacing.x5,
              AppSpacing.x4,
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Pfade anzeigen'),
            ),
          ),
        ],
      ),
    );
  }
}
