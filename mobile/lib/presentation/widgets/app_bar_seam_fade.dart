import 'package:flutter/material.dart';

/// Adds a soft fade at the bottom edge of transparent app bars so scrolling
/// content blends into the toolbar without a hard seam.
class AppBarSeamFade extends StatelessWidget {
  const AppBarSeamFade({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  surface.withValues(alpha: 0.40),
                  surface.withValues(alpha: 0.16),
                  surface.withValues(alpha: 0),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
