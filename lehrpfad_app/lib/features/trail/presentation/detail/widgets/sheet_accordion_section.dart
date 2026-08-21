import 'package:flutter/material.dart';

/// Eingeklappter Abschnitt im Trail-Sheet (Material-3 ExpansionTile).
///
/// Beim Öffnen scrollt das Parent-Scrollable nach der Expand-Animation
/// smooth zum Header.
class SheetAccordionSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SheetAccordionSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  State<SheetAccordionSection> createState() => _SheetAccordionSectionState();
}

class _SheetAccordionSectionState extends State<SheetAccordionSection> {
  static const _expandDuration = Duration(milliseconds: 200);
  static const _scrollDuration = Duration(milliseconds: 450);

  final GlobalKey _headerKey = GlobalKey();
  int _scrollToken = 0;

  void _onExpansionChanged(bool expanded) {
    _scrollToken++;
    if (!expanded) return;

    final token = _scrollToken;
    Future<void>.delayed(_expandDuration, () {
      if (!mounted || token != _scrollToken) return;
      final headerContext = _headerKey.currentContext;
      if (headerContext == null) return;
      Scrollable.ensureVisible(
        headerContext,
        duration: _scrollDuration,
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  @override
  void dispose() {
    _scrollToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      expansionAnimationStyle: const AnimationStyle(
        duration: _expandDuration,
        curve: Curves.easeIn,
      ),
      onExpansionChanged: _onExpansionChanged,
      title: KeyedSubtree(
        key: _headerKey,
        child: Text(widget.title, style: theme.textTheme.titleMedium),
      ),
      subtitle: widget.subtitle == null
          ? null
          : Text(widget.subtitle!, style: theme.textTheme.bodySmall),
      children: widget.children,
    );
  }
}
