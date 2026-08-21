import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/trail_image.dart';

/// Vollbild-Ansicht fuer Bilder: Wischen zwischen Bildern, Zoomen per
/// Pinch (InteractiveViewer), Credit-Zeile und optionaler Loesch-Button.
class FullscreenImageViewer extends StatefulWidget {
  final List<TrailImage> images;
  final int initialIndex;

  /// Wird aufgerufen, wenn der User das aktuelle Bild loeschen moechte
  /// (eigene Bilder oder Admin). Soll das Bild loeschen und true
  /// zurueckgeben, damit der Viewer sich schliesst.
  final Future<bool> Function(TrailImage image)? onDelete;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onDelete,
  });

  static Future<void> open(
    BuildContext context,
    List<TrailImage> images,
    int initialIndex, {
    Future<bool> Function(TrailImage image)? onDelete,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final image = widget.images[_index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bild löschen?'),
        content: const Text('Das Bild wird dauerhaft entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await widget.onDelete!(image);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_index];
    return Scaffold(
      backgroundColor: AppColors.n950,
      appBar: AppBar(
        backgroundColor: AppColors.n950,
        foregroundColor: AppColors.n50,
        title: Text('${_index + 1} / ${widget.images.length}'),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Bild löschen',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: CachedNetworkAvifImage(
                  widget.images[i].mediumUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.n50),
                    );
                  },
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.onImage54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          if (image.credit.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                '© ${image.credit}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onImage70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
