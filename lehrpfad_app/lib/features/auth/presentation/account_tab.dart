import 'package:flutter/material.dart';

import 'account_panel.dart';

/// Konto-Tab der Bottom-Navigation.
class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konto')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 8),
          child: AccountPanel(),
        ),
      ),
    );
  }
}
