import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/apple_hig_tokens.dart';
import '../../widgets/ios_liquid_glass_tab_bar.dart';

class MainTabsScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainTabsScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTabSelected(int index) {
    AppHaptics.selection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: IOSLiquidGlassTabBar(
        selectedIndex: navigationShell.currentIndex,
        onTabSelected: _onTabSelected,
        onCenterAction: () {
          AppHaptics.selection();
          context.push('/scan-qr');
        },
        centerIcon: LucideIcons.scanLine,
        centerLabel: 'Quét QR',
        accentColor: AppColors.primary,
        items: const [
          IOSLiquidGlassTabItem(
            label: 'Trang chủ',
            icon: LucideIcons.house,
            selectedIcon: LucideIcons.house,
            tabType: AnimatedTabType.home,
          ),
          IOSLiquidGlassTabItem(
            label: 'Thẻ',
            icon: LucideIcons.creditCard,
            selectedIcon: LucideIcons.creditCard,
            tabType: AnimatedTabType.cards,
          ),
          IOSLiquidGlassTabItem(
            label: 'Ưu đãi',
            icon: LucideIcons.gift,
            selectedIcon: LucideIcons.gift,
            hasDotBadge: true,
            tabType: AnimatedTabType.gift,
          ),
          IOSLiquidGlassTabItem(
            label: 'Xem thêm',
            icon: LucideIcons.layoutGrid,
            selectedIcon: LucideIcons.layoutGrid,
            tabType: AnimatedTabType.more,
          ),
        ],
      ),
    );
  }
}
