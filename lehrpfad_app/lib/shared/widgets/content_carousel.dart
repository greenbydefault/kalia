import 'package:flutter/material.dart';

import 'content_carousel_style.dart';
import 'page_dots.dart';
import 'snapping_page_behavior.dart';

/// Horizontaler Slider mit Slide-Snap und Dots. Layout über [ContentCarouselStyle].
class ContentCarousel<T> extends StatefulWidget {
  const ContentCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.layout = ContentCarouselLayout.peek,
  });

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final ContentCarouselLayout layout;

  @override
  State<ContentCarousel<T>> createState() => _ContentCarouselState<T>();
}

class _ContentCarouselState<T> extends State<ContentCarousel<T>> {
  PageController? _controller;
  int _index = 0;

  int get _pageSize => ContentCarouselStyle.pageSize(widget.layout);
  double get _height => ContentCarouselStyle.height(widget.layout);
  double get _viewportFraction =>
      ContentCarouselStyle.viewportFraction(widget.layout);

  int get _pageCount => (widget.items.length / _pageSize).ceil();

  List<List<T>> get _pages {
    final items = widget.items;
    final pages = <List<T>>[];
    for (var i = 0; i < items.length; i += _pageSize) {
      final end = (i + _pageSize).clamp(0, items.length);
      pages.add(items.sublist(i, end));
    }
    return pages;
  }

  @override
  void initState() {
    super.initState();
    if (_pageCount > 1) {
      _controller = PageController(viewportFraction: _viewportFraction);
    }
  }

  @override
  void didUpdateWidget(covariant ContentCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPageSize = ContentCarouselStyle.pageSize(oldWidget.layout);
    final wasMulti = (oldWidget.items.length / oldPageSize).ceil() > 1;
    final isMulti = _pageCount > 1;
    final oldFraction = ContentCarouselStyle.viewportFraction(oldWidget.layout);
    if (wasMulti != isMulti || oldFraction != _viewportFraction) {
      _controller?.dispose();
      _controller =
          isMulti ? PageController(viewportFraction: _viewportFraction) : null;
      _index = 0;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _slideRow(List<T> page) {
    return Row(
      children: [
        for (var i = 0; i < page.length; i++) ...[
          if (i > 0) const SizedBox(width: ContentCarouselStyle.gap),
          Expanded(child: widget.itemBuilder(page[i])),
        ],
        if (page.length < _pageSize && _pageCount > 1)
          for (var i = page.length; i < _pageSize; i++) ...[
            const SizedBox(width: ContentCarouselStyle.gap),
            const Expanded(child: SizedBox.shrink()),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final pages = _pages;
    final pageCount = pages.length;

    if (pageCount == 1) {
      return SizedBox(
        height: _height,
        child: _slideRow(pages.first),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: _height,
          child: SnappingPager(
            controller: _controller!,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: pageCount,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(
                    right: ContentCarouselStyle.gap,
                  ),
                  child: _slideRow(pages[i]),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: ContentCarouselStyle.gap),
          child: PageDots(count: pageCount, index: _index),
        ),
      ],
    );
  }
}
