import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../widgets/floating_glass_bottom_bar.dart';

class MainTabsScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainTabsScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onQuickAction(BuildContext context) {
    context.push('/scan-qr');
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      contentAwareBrightness: false,
      backgroundColor: Colors.transparent,
      bottomBarHeight: 88,
      bottomBar: RepaintBoundary(
        child: FloatingGlassBottomBar(
          selectedIndex: navigationShell.currentIndex,
          onTabSelected: _onTabSelected,
          onQuickActionPressed: () => _onQuickAction(context),
        ),
      ),
      body: RepaintBoundary(
        child: navigationShell,
      ),
    );
  }
}

