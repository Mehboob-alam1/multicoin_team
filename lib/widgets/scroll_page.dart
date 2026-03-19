import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A scrollable page body with consistent padding and bottom space for the floating nav.
/// Use for tab content (dashboard, shop, rewards, etc.) so layout is flexible and consistent.
class ScrollPage extends StatelessWidget {
  final Widget child;
  final ScrollPhysics? physics;
  final bool safeArea;
  final double? horizontalPadding;

  const ScrollPage({
    super.key,
    required this.child,
    this.physics,
    this.safeArea = true,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppTheme.pagePadding(context);
    final hPad = horizontalPadding ?? AppTheme.pagePaddingH;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppTheme.pagePaddingV,
        hPad,
        padding.bottom,
      ),
      child: child,
    );
    final scroll = CustomScrollView(
      physics: physics ?? const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: content),
      ],
    );
    if (safeArea) {
      return SafeArea(
        top: true,
        bottom: false,
        left: true,
        right: true,
        child: scroll,
      );
    }
    return scroll;
  }
}

/// Single-child version: one Column/Widget as direct child (wrapped in SliverToBoxAdapter).
class ScrollPageSingle extends StatelessWidget {
  final Widget child;
  final ScrollPhysics? physics;

  const ScrollPageSingle({super.key, required this.child, this.physics});

  @override
  Widget build(BuildContext context) {
    final padding = AppTheme.pagePadding(context);
    return SafeArea(
      top: true,
      bottom: false,
      left: true,
      right: true,
      child: SingleChildScrollView(
        physics: physics ?? const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppTheme.pagePaddingH,
          AppTheme.pagePaddingV,
          AppTheme.pagePaddingH,
          padding.bottom,
        ),
        child: child,
      ),
    );
  }
}
