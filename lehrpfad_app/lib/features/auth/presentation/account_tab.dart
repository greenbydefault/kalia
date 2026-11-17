import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_tab_provider.dart';
import '../../community/data/photos_seen.dart';
import 'account_contributions_tab.dart';
import 'account_panel.dart';
import 'account_settings_tab.dart';

/// Index des Konto-Tabs in der Bottom-Navigation.
const kAccountShellIndex = 4;

/// Konto-Tab der Bottom-Navigation: kompakter Profilkopf, darunter zwei
/// Tabs „Meine Beiträge“ (Fotos, Kommentare, Meldungen) und
/// „Einstellungen“. Jeder Tab scrollt für sich, der Kopf bleibt stehen.
class AccountTab extends ConsumerStatefulWidget {
  const AccountTab({super.key});

  @override
  ConsumerState<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends ConsumerState<AccountTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  /// Fotos mit neuer Entscheidung, die beim Öffnen des Beitrags-Tabs noch
  /// ungesehen waren. Der Zeitstempel ist dann schon gesetzt, der „Neu“-
  /// Hinweis bleibt, bis der Nutzer den Tab verlässt.
  Set<String> _fresh = const {};

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_syncSeen);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _contributionsVisible =>
      ref.read(shellTabIndexProvider) == kAccountShellIndex && _tabs.index == 0;

  void _syncSeen() {
    if (!mounted) return;
    if (!_contributionsVisible) {
      if (_fresh.isNotEmpty) setState(() => _fresh = const {});
      return;
    }
    final unseen = ref.read(unseenDecisionImagesProvider);
    if (unseen.isEmpty) return;
    setState(() => _fresh = {..._fresh, for (final i in unseen) i.id});
    ref.read(photosSeenAtProvider.notifier).markSeen();
  }

  @override
  Widget build(BuildContext context) {
    // Tab-Wechsel der Shell und neue Entscheidungen lösen den Abgleich aus.
    ref.listen<int>(shellTabIndexProvider, (_, _) => _syncSeen());
    ref.listen(unseenDecisionImagesProvider, (_, _) => _syncSeen());
    final hasUnseen = ref.watch(hasUnseenDecisionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Konto')),
      body: SafeArea(
        child: Column(
          children: [
            const AccountPanel(),
            TabBar(
              controller: _tabs,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Meine Beiträge'),
                      if (hasUnseen)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Tab(text: 'Einstellungen'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  AccountContributionsTab(fresh: _fresh),
                  const AccountSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
