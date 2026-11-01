import 'package:flutter/material.dart';

/// Retains each tab's navigation state while keeping inactive branches idle.
/// Native tab navigation switches content immediately; animating and scaling
/// two complete banking screens at once adds raster work without helping the
/// user's understanding of the tab change.
class AnimatedBranchContainer extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(children.length, (index) {
        final isActive = index == currentIndex;
        return Offstage(
          offstage: !isActive,
          child: TickerMode(
            enabled: isActive,
            child: IgnorePointer(
              ignoring: !isActive,
              child: children[index],
            ),
          ),
        );
      }),
    );
  }
}
