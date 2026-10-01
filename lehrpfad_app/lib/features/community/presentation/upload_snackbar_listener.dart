import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/upload_jobs.dart';

/// Zeigt pro fertigem Foto-Upload eine Snackbar (Erfolg und Fehler), egal
/// ob das Upload-Sheet noch offen ist. Sitzt in der Shell, damit der
/// ScaffoldMessenger das Schliessen des Sheets ueberlebt.
class UploadSnackbarListener extends ConsumerStatefulWidget {
  const UploadSnackbarListener({super.key});

  @override
  ConsumerState<UploadSnackbarListener> createState() =>
      _UploadSnackbarListenerState();
}

class _UploadSnackbarListenerState
    extends ConsumerState<UploadSnackbarListener> {
  StreamSubscription<UploadResult>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(uploadJobsProvider.notifier).results.listen(_show);
  }

  void _show(UploadResult result) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
