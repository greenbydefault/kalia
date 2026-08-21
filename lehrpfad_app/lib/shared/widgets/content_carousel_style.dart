import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Layout-Kategorien für Content-Slider (Stationen, Arten, Geräte).
enum ContentCarouselLayout { peek, compact3 }

/// Einzige Zahlenquelle für Carousel- und Kachel-Chrome.
abstract final class ContentCarouselStyle {
  static int pageSize(ContentCarouselLayout layout) => switch (layout) {
        ContentCarouselLayout.peek => 1,
        ContentCarouselLayout.compact3 => 3,
      };

  static double height(ContentCarouselLayout layout) => switch (layout) {
        ContentCarouselLayout.peek => 156,
        ContentCarouselLayout.compact3 => 112,
      };

  static double viewportFraction(ContentCarouselLayout layout) =>
      switch (layout) {
        ContentCarouselLayout.peek => 0.88,
        ContentCarouselLayout.compact3 => 0.91,
      };

  static EdgeInsets tilePadding(ContentCarouselLayout layout) =>
      switch (layout) {
        ContentCarouselLayout.peek => const EdgeInsets.fromLTRB(12, 10, 4, 10),
        ContentCarouselLayout.compact3 =>
          const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      };

  static const double gap = 8;
  static const double radius = 10;
  static const Color fill = AppColors.n100;
  static const double dotSize = 7;
  static const double dotGap = 3;
  static const double iconSize = 28;
}
