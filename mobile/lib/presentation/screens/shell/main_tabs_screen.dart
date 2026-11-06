import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        centerLabel: 'Quét QR',
        accentColor: AppColors.primary,
        items: const [
          IOSLiquidGlassTabItem(
            label: 'Trang chủ',
            icon: CupertinoIcons.house,
            selectedIcon: CupertinoIcons.house_fill,
          ),
          IOSLiquidGlassTabItem(
            label: 'Thẻ',
            icon: CupertinoIcons.creditcard,
            selectedIcon: CupertinoIcons.creditcard_fill,
          ),
          IOSLiquidGlassTabItem(
            label: 'Ưu đãi',
            icon: CupertinoIcons.gift,
            selectedIcon: CupertinoIcons.gift_fill,
            hasDotBadge: true,
          ),
          IOSLiquidGlassTabItem(
            label: 'Xem thêm',
            icon: CupertinoIcons.ellipsis_circle,
            selectedIcon: CupertinoIcons.ellipsis_circle_fill,
          ),
        ],
      ),
    );
  }
}
