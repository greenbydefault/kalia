import 'package:flutter/material.dart';

import 'account_panel.dart';

/// Modal-Account-Sheet (Legacy-Einstieg; Tab nutzt [AccountPanel] direkt).
class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: AccountPanel(padForKeyboard: true),
    );
  }
}
