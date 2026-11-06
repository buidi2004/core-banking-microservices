import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Item dữ liệu cho từng tab trong thanh điều hướng iOS Liquid Glass
class IOSLiquidGlassTabItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;
  final bool hasDotBadge;

  const IOSLiquidGlassTabItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
    this.hasDotBadge = false,
  });
}

/// Hằng số quang học và vật lý đo chuẩn từng frame từ UIKit iOS 26 Liquid Glass
/// (Nguồn: slaviboy/iOSGlassNavigation & Liquidum project)
class _GlassConstants {
  static const double barHeight = 62.0;
  static const double barMargin = 21.0;
  static const double barInset = 4.0;
  static const double lensGrow = 8.0; // Viên kính phồng to 8dp mỗi phía khi nhấc lên
  static const double selectedContentScale = 1.16; // Nội dung phóng to 1.16x trong thấu kính
  static const double swell = 0.0355; // Thanh platter phình 3.55% khi chạm
  static const double stretchMax = 0.08;
  static const double glowDiameter = 93.0;
  static const double glowOpacity = 0.2845;

  // Timings (giây)
  static const int liftDelayMs = 15;
  static const int lensHangTimeMs = 220;

  // Đổ bóng (dp)
  static const double platterShadowOffset = 8.0;
  static const double platterShadowRadius = 24.0;
  static const double platterShadowAlpha = 0.12;

  static const double lensShadowOffset = 7.0;
  static const double lensShadowRadius = 10.0;
  static const double lensShadowAlpha = 0.16;
}

/// Tái hiện 100% thanh điều hướng iOS 26 Liquid Glass Navigation Bar
/// Thư viện gốc: https://github.com/slaviboy/iOSGlassNavigation
class IOSLiquidGlassTabBar extends StatefulWidget {
  final List<IOSLiquidGlassTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onTabReselected;
  final Color? accentColor;

  /// Tùy chọn Action ở chính giữa thanh bottom bar (ví dụ: Quét mã QR)
  final VoidCallback? onCenterAction;
  final String? centerLabel;
  final IconData? centerIcon;

  const IOSLiquidGlassTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onTabReselected,
    this.accentColor,
    this.onCenterAction,
    this.centerLabel = 'Quét QR',
    this.centerIcon = CupertinoIcons.qrcode_viewfinder,
  });

  @override
  State<IOSLiquidGlassTabBar> createState() => _IOSLiquidGlassTabBarState();
}

class _IOSLiquidGlassTabBarState extends State<IOSLiquidGlassTabBar>
    with TickerProviderStateMixin {
  // Bộ điều khiển hiệu ứng vật lý lò xo (Spring Physics)
  late AnimationController _liftController; // Độ nâng thấu kính (0.0: nghỉ -> 1.0: nhấc lên thành giọt)
  late AnimationController _swellController; // Độ phình của thanh đáy
  late AnimationController _lensPositionController; // Vị trí phân đoạn (0.0 .. slots - 1)

  Timer? _liftTimer;
  Timer? _hangTimer;

  bool _isDragging = false;
  bool _isCenterPressed = false;
  Offset _pointerPos = Offset.zero;
  int _lastHapticCrossedIndex = -1;
  double _stretchX = 0.0; // Độ biến dạng kéo giãn của giọt nước theo vận tốc

  bool get _hasCenter => widget.onCenterAction != null;
  int get _totalSlots => _hasCenter ? widget.items.length + 1 : widget.items.length;
  int get _centerSlotIndex => _hasCenter ? _totalSlots ~/ 2 : -1;

  double _tabIndexToSlot(int tabIndex) {
    if (!_hasCenter) return tabIndex.toDouble();
    if (tabIndex < _centerSlotIndex) return tabIndex.toDouble();
    return (tabIndex + 1).toDouble();
  }

  int? _slotToTabIndex(int slot) {
    if (!_hasCenter) return slot.clamp(0, widget.items.length - 1);
    if (slot == _centerSlotIndex) return null; // Nút trung tâm (Quét QR)
    if (slot < _centerSlotIndex) return slot.clamp(0, widget.items.length - 1);
    return (slot - 1).clamp(0, widget.items.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _lastHapticCrossedIndex = _tabIndexToSlot(widget.selectedIndex).round();

    // Lò xo nâng giọt kính (Critically Damped Spring)
    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Lò xo phình thanh platter
    _swellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    // Lò xo đuổi theo ngón tay (Lens Catch-Up Spring)
    _lensPositionController = AnimationController.unbounded(
      vsync: this,
      value: _tabIndexToSlot(widget.selectedIndex),
    );
  }

  @override
  void didUpdateWidget(covariant IOSLiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_isDragging) {
      _animateLensTo(_tabIndexToSlot(widget.selectedIndex));
    }
  }

  @override
  void dispose() {
    _liftTimer?.cancel();
    _hangTimer?.cancel();
    _liftController.dispose();
    _swellController.dispose();
    _lensPositionController.dispose();
    super.dispose();
  }

  void _animateLensTo(double targetSlot) {
    final simulation = SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 380.0, damping: 26.0),
      _lensPositionController.value,
      targetSlot,
      0.0,
    );
    _lensPositionController.animateWith(simulation);
  }

  void _handlePointerDown(PointerDownEvent event, BoxConstraints constraints) {
    _hangTimer?.cancel();
    _isDragging = true;
    _pointerPos = event.localPosition;

    final barWidth = constraints.maxWidth;
    final usableWidth = barWidth - 2 * _GlassConstants.barInset;
    final slotWidth = usableWidth / _totalSlots;
    final localX = (_pointerPos.dx - _GlassConstants.barInset).clamp(0.0, usableWidth);
    final touchSlotIndex = (localX / slotWidth).floor().clamp(0, _totalSlots - 1);

    _swellController.forward();

    if (_hasCenter && touchSlotIndex == _centerSlotIndex) {
      setState(() {
        _isCenterPressed = true;
      });
      HapticFeedback.selectionClick();
      return;
    }

    setState(() {
      _isCenterPressed = false;
    });

    // Độ trễ nâng kính 15ms chuẩn UIKit (LiftDelay)
    _liftTimer = Timer(const Duration(milliseconds: _GlassConstants.liftDelayMs), () {
      if (mounted && _isDragging && !_isCenterPressed) {
        _liftController.forward();
      }
    });

    _animateLensTo(touchSlotIndex.toDouble());
    _checkTabCrossed(touchSlotIndex);
  }

  void _handlePointerMove(PointerMoveEvent event, BoxConstraints constraints) {
    if (!_isDragging) return;
    _pointerPos = event.localPosition;

    final barWidth = constraints.maxWidth;
    final usableWidth = barWidth - 2 * _GlassConstants.barInset;
    final slotWidth = usableWidth / _totalSlots;
    final localX = (_pointerPos.dx - _GlassConstants.barInset).clamp(0.0, usableWidth);
    final targetFraction = ((localX / slotWidth) - 0.5).clamp(0.0, (_totalSlots - 1).toDouble());

    if (_isCenterPressed) {
      if ((targetFraction - _centerSlotIndex).abs() > 0.45) {
        setState(() {
          _isCenterPressed = false;
        });
        _liftController.forward();
      } else {
        return;
      }
    }

    // Tính độ biến dạng kéo dãn giọt nước theo quán tính di chuyển
    final diff = targetFraction - _lensPositionController.value;
    setState(() {
      _stretchX = (diff * 0.08).clamp(-_GlassConstants.stretchMax, _GlassConstants.stretchMax);
    });

    _animateLensTo(targetFraction);
    _checkTabCrossed(targetFraction.round());
  }

  void _handlePointerUp(PointerUpEvent event, BoxConstraints constraints) {
    _finishInteraction(constraints);
  }

  void _handlePointerCancel(PointerCancelEvent event, BoxConstraints constraints) {
    _finishInteraction(constraints);
  }

  void _finishInteraction(BoxConstraints constraints) {
    _isDragging = false;
    _liftTimer?.cancel();

    _swellController.reverse();

    if (_hasCenter && _isCenterPressed) {
      setState(() {
        _isCenterPressed = false;
        _stretchX = 0.0;
      });
      HapticFeedback.mediumImpact();
      widget.onCenterAction?.call();
      _animateLensTo(_tabIndexToSlot(widget.selectedIndex));
      return;
    }

    final barWidth = constraints.maxWidth;
    final usableWidth = barWidth - 2 * _GlassConstants.barInset;
    final slotWidth = usableWidth / _totalSlots;
    final localX = (_pointerPos.dx - _GlassConstants.barInset).clamp(0.0, usableWidth);
    final rawSlotIndex = (localX / slotWidth).floor().clamp(0, _totalSlots - 1);
    final tabIndex = _slotToTabIndex(rawSlotIndex);

    if (tabIndex == null) {
      // Nhả tay đúng ngay trên nút Quét QR trung tâm
      setState(() {
        _stretchX = 0.0;
      });
      HapticFeedback.mediumImpact();
      widget.onCenterAction?.call();
      _animateLensTo(_tabIndexToSlot(widget.selectedIndex));
    } else {
      final targetSlot = _tabIndexToSlot(tabIndex);
      _animateLensTo(targetSlot);
      setState(() {
        _stretchX = 0.0;
      });

      if (tabIndex != widget.selectedIndex) {
        HapticFeedback.mediumImpact();
        widget.onTabSelected(tabIndex);
      } else {
        widget.onTabReselected?.call();
      }
    }

    // Treo thấu kính 220ms (LensHangTime) trước khi hạ xuống trở lại platter
    _hangTimer = Timer(const Duration(milliseconds: _GlassConstants.lensHangTimeMs), () {
      if (mounted && !_isDragging) {
        _liftController.reverse();
      }
    });
  }

  void _checkTabCrossed(int slot) {
    if (slot != _lastHapticCrossedIndex && slot >= 0 && slot < _totalSlots) {
      _lastHapticCrossedIndex = slot;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final accent = widget.accentColor ?? (isDark ? AppColors.bottomBarCyan : AppColors.primary);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _GlassConstants.barMargin,
        0,
        _GlassConstants.barMargin,
        math.max(_GlassConstants.barMargin, bottomPadding + 4.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final slotCount = _totalSlots;
          final usableWidth = barWidth - 2 * _GlassConstants.barInset;
          final tabWidth = usableWidth / slotCount;

          return Listener(
            onPointerDown: (e) => _handlePointerDown(e, constraints),
            onPointerMove: (e) => _handlePointerMove(e, constraints),
            onPointerUp: (e) => _handlePointerUp(e, constraints),
            onPointerCancel: (e) => _handlePointerCancel(e, constraints),
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _liftController,
                _swellController,
                _lensPositionController,
              ]),
              builder: (context, child) {
                final lift = _liftController.value;
                final swell = _swellController.value * _GlassConstants.swell;
                final lensIndex = _lensPositionController.value;

                // Tọa độ tâm thấu kính (Lens Center)
                final lensCenterX = _GlassConstants.barInset + (lensIndex + 0.5) * tabWidth;
                const lensCenterY = _GlassConstants.barHeight / 2;

                // Kích thước thấu kính: Khi nâng (lift=1), phình thêm 8dp mọi phía
                final currentLensWidth = (tabWidth - 4.0) + (lift * _GlassConstants.lensGrow * 2);
                final currentLensHeight = (_GlassConstants.barHeight - 2 * _GlassConstants.barInset) +
                    (lift * _GlassConstants.lensGrow * 2);
                final currentLensRadius = currentLensHeight / 2;

                final lensRect = Rect.fromCenter(
                  center: Offset(lensCenterX, lensCenterY),
                  width: currentLensWidth * (1.0 + _stretchX.abs()),
                  height: currentLensHeight,
                );

                return Transform.scale(
                  scale: 1.0 + swell,
                  child: SizedBox(
                    height: _GlassConstants.barHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // -------------------------------------------------------------
                        // LAYER 1: NỀN KHỐI KÍNH NẰM DƯỚI (PLATTER GLASS CAPSULE)
                        // -------------------------------------------------------------
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PlatterGlassPainter(
                              isDark: isDark,
                              radius: _GlassConstants.barHeight / 2,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_GlassConstants.barHeight / 2),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                                child: Container(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.68),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // -------------------------------------------------------------
                        // LAYER 2: GIỌT KÍNH THẤU KÍNH NÂNG NỔI (LIFTED LENS DROPLET)
                        // -------------------------------------------------------------
                        Positioned(
                          left: lensRect.left,
                          top: lensRect.top,
                          width: lensRect.width,
                          height: lensRect.height,
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _LensDropletPainter(
                                lift: lift,
                                radius: currentLensRadius,
                                isDark: isDark,
                                accentColor: accent,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(currentLensRadius),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4.0 + (lift * 12.0),
                                    sigmaY: 4.0 + (lift * 12.0),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? accent.withOpacity(0.12 + (lift * 0.10))
                                          : accent.withOpacity(0.16 + (lift * 0.08)),
                                      borderRadius: BorderRadius.circular(currentLensRadius),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // -------------------------------------------------------------
                        // LAYER 3: VẦNG SÁNG ĐẦU NGÓN TAY (FINGERTIP GLOW)
                        // -------------------------------------------------------------
                        if (_isDragging && lift > 0.05)
                          Positioned(
                            left: _pointerPos.dx - (_GlassConstants.glowDiameter / 2),
                            top: _pointerPos.dy - (_GlassConstants.glowDiameter / 2),
                            width: _GlassConstants.glowDiameter,
                            height: _GlassConstants.glowDiameter,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _FingertipGlowPainter(
                                  alpha: _GlassConstants.glowOpacity * lift,
                                  accentColor: accent,
                                ),
                              ),
                            ),
                          ),

                        // -------------------------------------------------------------
                        // LAYER 4: NỘI DUNG TỪNG TAB & NÚT QUÉT QR TRUNG TÂM (1.16x ZOOM)
                        // -------------------------------------------------------------
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _GlassConstants.barInset,
                            ),
                            child: Row(
                              children: List.generate(slotCount, (i) {
                                if (_hasCenter && i == _centerSlotIndex) {
                                  final distanceToLens = (lensIndex - i).abs();
                                  final isInsideLens = distanceToLens < 0.65;
                                  final contentScale = 1.0 +
                                      (isInsideLens
                                          ? (_GlassConstants.selectedContentScale - 1.0) *
                                              (1.0 - distanceToLens).clamp(0.0, 1.0)
                                          : 0.0);

                                  return Expanded(
                                    child: _buildCenterActionButton(
                                      isDark: isDark,
                                      accentColor: accent,
                                      slotWidth: tabWidth,
                                      contentScale: contentScale,
                                    ),
                                  );
                                }

                                final tabIndex = _slotToTabIndex(i)!;
                                final item = widget.items[tabIndex];
                                final isSelected = widget.selectedIndex == tabIndex;

                                // Tính khoảng cách tương đối tới tâm thấu kính (0.0: nằm chính giữa)
                                final distanceToLens = (lensIndex - i).abs();
                                final isInsideLens = distanceToLens < 0.65;

                                // Tỷ lệ phóng đại 1.16x bên trong thấu kính (SelectedContentScale)
                                final contentScale = 1.0 +
                                    (isInsideLens
                                        ? (_GlassConstants.selectedContentScale - 1.0) *
                                            (1.0 - distanceToLens).clamp(0.0, 1.0)
                                        : 0.0);

                                final tabColor = isSelected || isInsideLens
                                    ? accent
                                    : (isDark
                                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                                        : CupertinoColors.secondaryLabel
                                            .resolveFrom(context)
                                            .withOpacity(0.85));

                                return Expanded(
                                  child: Transform.scale(
                                    scale: contentScale,
                                    child: _buildTabContent(
                                      item: item,
                                      isSelected: isSelected,
                                      accentColor: tabColor,
                                      isInsideLens: isInsideLens,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterActionButton({
    required bool isDark,
    required Color accentColor,
    required double slotWidth,
    required double contentScale,
  }) {
    return Center(
      child: AnimatedScale(
        scale: (_isCenterPressed ? 0.90 : 1.0) * contentScale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0066CC),
                      Color(0xFF00B4D8),
                      Color(0xFF0056B3),
                    ]
                  : const [
                      Color(0xFF00B4D8),
                      Color(0xFF0066CC),
                      Color(0xFF003366),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.85 : 0.70),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(isDark ? 0.50 : 0.35),
                blurRadius: 10,
                spreadRadius: 0.5,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              widget.centerIcon ?? CupertinoIcons.qrcode_viewfinder,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required IOSLiquidGlassTabItem item,
    required bool isSelected,
    required Color accentColor,
    required bool isInsideLens,
  }) {
    final iconData = (isSelected && item.selectedIcon != null)
        ? item.selectedIcon!
        : item.icon;

    return Center(
      child: Semantics(
        label: item.label,
        selected: isSelected,
        button: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              iconData,
              size: 24,
              color: accentColor,
            ),
            if (item.badgeCount != null && item.badgeCount! > 0)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30), // iOS System Red
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (item.hasDotBadge)
              Positioned(
                top: -1,
                right: -3,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter vẽ khối kính Platter bên dưới (Bao gồm bóng Gaussian đổ và viền Specular phản chiếu)
class _PlatterGlassPainter extends CustomPainter {
  final bool isDark;
  final double radius;

  _PlatterGlassPainter({
    required this.isDark,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1. Bóng đổ Gaussian mềm mại bên dưới (Platter Soft Contact Shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.35 : _GlassConstants.platterShadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _GlassConstants.platterShadowRadius);

    canvas.drawRRect(
      rrect.shift(const Offset(0, _GlassConstants.platterShadowOffset)),
      shadowPaint,
    );

    // 2. Viền vát quang học mạ ánh bạc Specular Bevel Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0x99FFFFFF), // Bắt sáng mạnh mép trên-trái
                Color(0x22FFFFFF),
                Color(0x1564748B),
                Color(0x40000000), // Mép dưới sẫm màu
              ]
            : const [
                Color(0xE6FFFFFF), // Sáng rực rỡ mép trên-trái
                Color(0x66FFFFFF), // White with opacity (border)
                Color(0x33B0BEC5),
                Color(0x2578909C),
              ],
        stops: const [0.0, 0.25, 0.70, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect.deflate(0.45), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _PlatterGlassPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.radius != radius;
}

/// Painter vẽ giọt kính thấu kính nâng nổi (Lifted Droplet Lens)
/// Tái tạo chính xác viền tán sắc quang học 7 điểm (Chromatic Dispersion Aberration Rim)
class _LensDropletPainter extends CustomPainter {
  final double lift;
  final double radius;
  final bool isDark;
  final Color accentColor;

  _LensDropletPainter({
    required this.lift,
    required this.radius,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1. Bóng nổi độc lập khi giọt thấu kính nhấc lên khỏi thanh đáy
    if (lift > 0.05) {
      final lensShadowPaint = Paint()
        ..color = Colors.black.withOpacity(_GlassConstants.lensShadowAlpha * lift)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          _GlassConstants.lensShadowRadius * lift,
        );

      canvas.drawRRect(
        rrect.shift(Offset(0, _GlassConstants.lensShadowOffset * lift)),
        lensShadowPaint,
      );
    }

    // 2. Viền tán sắc quang phổ 7 màu (7-tap Chromatic Aberration Dispersion Rim)
    // Đặc trưng cốt lõi của thấu kính Liquid Glass trên iOS 26
    final dispersionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 + (lift * 0.8)
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: isDark
            ? [
                AppColors.bottomBarOcean.withOpacity(0.85), // Cyan accent
                const Color(0xFF3B82F6).withOpacity(0.70), // Tailwind Blue accent (allowed exception)
                const Color(0xFF8B5CF6).withOpacity(0.80), // Violet
                const Color(0xFFEC4899).withOpacity(0.85), // Magenta
                const Color(0xFFF59E0B).withOpacity(0.70), // Amber
                const Color(0xFF10B981).withOpacity(0.80), // Emerald
                AppColors.bottomBarOcean.withOpacity(0.85), // Loop back - use token
              ]
            : [
                const Color(0xFF00B4D8).withOpacity(0.80),
                const Color(0xFF6366F1).withOpacity(0.70),
                const Color(0xFFA855F7).withOpacity(0.75),
                const Color(0xFFF43F5E).withOpacity(0.75),
                const Color(0xFFFBBF24).withOpacity(0.65),
                const Color(0xFF10B981).withOpacity(0.70),
                const Color(0xFF00B4D8).withOpacity(0.80),
              ],
        stops: const [0.0, 0.16, 0.33, 0.50, 0.67, 0.83, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect.deflate(0.6), dispersionPaint);

    // 3. Đường viền phản chiếu Specular Highlight mép trên đỉnh thấu kính
    final topShinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF), // Điểm sáng chói trên vòm thấu kính
          Color(0x40FFFFFF),
          Colors.transparent,
        ],
        stops: [0.0, 0.40, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect.deflate(0.5), topShinePaint);
  }

  @override
  bool shouldRepaint(covariant _LensDropletPainter oldDelegate) =>
      oldDelegate.lift != lift ||
      oldDelegate.radius != radius ||
      oldDelegate.isDark != isDark ||
      oldDelegate.accentColor != accentColor;
}

/// Painter vẽ vầng sáng tiếp xúc đầu ngón tay (Fingertip Touch Glow)
class _FingertipGlowPainter extends CustomPainter {
  final double alpha;
  final Color accentColor;

  _FingertipGlowPainter({
    required this.alpha,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.001) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(alpha),
          accentColor.withOpacity(alpha * 0.7),
          accentColor.withOpacity(alpha * 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FingertipGlowPainter oldDelegate) =>
      oldDelegate.alpha != alpha || oldDelegate.accentColor != accentColor;
}
