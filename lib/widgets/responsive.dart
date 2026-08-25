import 'package:flutter/material.dart';

/// Standard breakpoints used across the app.
abstract final class Breakpoints {
  /// Very small phones.
  static const double compact = 360;

  /// Phones / small tablets split view.
  static const double medium = 600;

  /// Tablets and desktop windows.
  static const double expanded = 900;

  /// Max width for readable body content on large screens.
  static const double maxContentWidth = 720;
}

extension ScreenSizeExt on BuildContext {
  /// True when the available width is below [Breakpoints.medium].
  bool get isCompact => MediaQuery.sizeOf(this).width < Breakpoints.medium;

  /// True when the available width is at least [Breakpoints.medium].
  bool get isWide => MediaQuery.sizeOf(this).width >= Breakpoints.medium;
}

/// Centers and constrains content width so the app scales gracefully
/// from phones up to tablets/desktop without stretched layouts.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lays out [children] as equal-width tiles whose height adapts to their
/// content. Unlike `GridView.count` with `childAspectRatio`, tiles can
/// never overflow vertically because height is intrinsic, not computed
/// from a fixed ratio.
///
/// The number of columns is derived from the available width: each tile
/// is guaranteed at least [minTileWidth] logical pixels.
class AutoGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  const AutoGrid({
    super.key,
    required this.children,
    this.minTileWidth = 150,
    this.spacing = 12,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final byWidth = ((width + spacing) / (minTileWidth + spacing)).floor();
        final columns = byWidth.clamp(1, maxColumns.clamp(1, children.length));
        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
