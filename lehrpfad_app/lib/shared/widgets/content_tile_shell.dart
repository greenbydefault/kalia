import 'package:flutter/material.dart';

import 'content_carousel_style.dart';

/// Gemeinsames Kachel-Chrome (Fill, Radius, Padding, InkWell).
class ContentTileShell extends StatelessWidget {
  const ContentTileShell({
    super.key,
    required this.onTap,
    required this.child,
    this.layout = ContentCarouselLayout.peek,
  });

  final VoidCallback onTap;
  final Widget child;
  final ContentCarouselLayout layout;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ContentCarouselStyle.radius);
    final padding = ContentCarouselStyle.tilePadding(layout);
    final expand = layout == ContentCarouselLayout.compact3;

    Widget inner = Padding(padding: padding, child: child);
    if (expand) {
      inner = SizedBox.expand(child: inner);
    }

    return Material(
      color: ContentCarouselStyle.fill,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: inner,
      ),
    );
  }
}
