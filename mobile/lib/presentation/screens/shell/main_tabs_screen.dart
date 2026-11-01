import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/apple_hig_tokens.dart';

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
    final systemBackground =
        CupertinoColors.systemBackground.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? systemBackground.withOpacity(0.78)
                  : systemBackground.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: CupertinoTabBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTabSelected,
                activeColor: AppColors.primary,
                inactiveColor: secondaryLabel,
                backgroundColor: Colors.transparent,
                border: null,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.house),
                    activeIcon: Icon(CupertinoIcons.house_fill),
                    label: 'Trang chủ',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.clock),
                    activeIcon: Icon(CupertinoIcons.clock_fill),
                    label: 'Giao dịch',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.gift),
                    activeIcon: Icon(CupertinoIcons.gift_fill),
                    label: 'Ưu đãi',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person),
                    activeIcon: Icon(CupertinoIcons.person_fill),
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
