import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/trail_bild.dart';
import 'trail_hero.dart';

/// Vollbild mit TASL (Title, Author, Source, License) für Seed-Hero-Fotos.
class TrailHeroFullscreen extends StatefulWidget {
  const TrailHeroFullscreen({
    super.key,
    required this.trailId,
    required this.bilder,
    required this.initialIndex,
  });

  final String trailId;
  final List<TrailBild> bilder;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required String trailId,
    required List<TrailBild> bilder,
    required int initialIndex,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrailHeroFullscreen(
          trailId: trailId,
          bilder: bilder,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<TrailHeroFullscreen> createState() => _TrailHeroFullscreenState();
}

class _TrailHeroFullscreenState extends State<TrailHeroFullscreen> {
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

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bild = widget.bilder[_index];
    return Scaffold(
      backgroundColor: AppColors.n950,
      appBar: AppBar(
        backgroundColor: AppColors.n950,
        foregroundColor: AppColors.n50,
        title: Text('${_index + 1} / ${widget.bilder.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.bilder.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final item = widget.bilder[i];
                return InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: TrailHeroImage(
                      trailId: widget.trailId,
                      bild: item,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x3,
                AppSpacing.x5,
                AppSpacing.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bild.caption.isNotEmpty)
                    Text(
                      bild.caption,
                      style: const TextStyle(
                        color: AppColors.n50,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (bild.credit.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Foto: ${bild.credit}',
                      style: const TextStyle(
                        color: AppColors.onImage70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (bild.sourceUrl.isNotEmpty)
                    _TaslLink(
                      label: 'Quelle',
                      onTap: () => _open(bild.sourceUrl),
                    ),
                  if (bild.licenseLabel.isNotEmpty)
                    _TaslLink(
                      label: bild.licenseUrl.isEmpty
                          ? bild.licenseLabel
                          : '${bild.licenseLabel} · Lizenztext',
                      onTap: bild.licenseUrl.isEmpty
                          ? null
                          : () => _open(bild.licenseUrl),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaslLink extends StatelessWidget {
  const _TaslLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.n50,
            fontSize: 13,
            decoration: onTap == null
                ? TextDecoration.none
                : TextDecoration.underline,
            decorationColor: AppColors.onImage70,
          ),
        ),
      ),
    );
  }
}
