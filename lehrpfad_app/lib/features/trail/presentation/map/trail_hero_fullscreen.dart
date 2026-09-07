import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../community/domain/trail_image.dart';
import 'trail_hero.dart';

/// Vollbild mit TASL (Title, Author, Source, License) für Seed-Hero-Fotos
/// und Credit für Community-Uploads.
class TrailHeroFullscreen extends StatefulWidget {
  const TrailHeroFullscreen({
    super.key,
    required this.trailId,
    required this.slides,
    required this.initialIndex,
  });

  final String trailId;
  final List<HeroSlide> slides;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required String trailId,
    required List<HeroSlide> slides,
    required int initialIndex,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrailHeroFullscreen(
          trailId: trailId,
          slides: slides,
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
    final slide = widget.slides[_index];
    return Scaffold(
      backgroundColor: AppColors.n950,
      appBar: AppBar(
        backgroundColor: AppColors.n950,
        foregroundColor: AppColors.n50,
        title: Text('${_index + 1} / ${widget.slides.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final item = widget.slides[i];
                return InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: TrailHeroImage(
                      trailId: widget.trailId,
                      slide: item,
                      fit: BoxFit.contain,
                      variant: TrailImageVariant.medium,
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
                  if (slide.caption.isNotEmpty)
                    Text(
                      slide.caption,
                      style: const TextStyle(
                        color: AppColors.n50,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (slide.credit.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Foto: ${slide.credit}',
                      style: const TextStyle(
                        color: AppColors.onImage70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (!slide.isNetwork && slide.sourceUrl.isNotEmpty)
                    _TaslLink(
                      label: 'Quelle',
                      onTap: () => _open(slide.sourceUrl),
                    ),
                  if (!slide.isNetwork && slide.licenseLabel.isNotEmpty)
                    _TaslLink(
                      label: slide.licenseUrl.isEmpty
                          ? slide.licenseLabel
                          : '${slide.licenseLabel} · Lizenztext',
                      onTap: slide.licenseUrl.isEmpty
                          ? null
                          : () => _open(slide.licenseUrl),
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
