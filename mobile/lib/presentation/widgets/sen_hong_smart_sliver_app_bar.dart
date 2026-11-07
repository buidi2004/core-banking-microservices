import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'animated_hint_ticker.dart';
import 'border_beam.dart';
import 'smart_search_modal_sheet.dart';

/// Nội dung thanh công cụ thông minh chuẩn giao diện mẫu:
/// - Góc bo cong duy nhất ở phía dưới bên trái (`bottomLeft: Radius.circular(34)`).
/// - Ô tìm kiếm viền Gradient chuyển sắc từ Xanh lục sang Xanh dương.
/// - Text Ticker tự động xoay vòng mượt mà giữa các gợi ý (Dán chuyển tiền AI, Tìm kiếm dịch vụ, Săn ưu đãi...).
/// - Icon Chuông thông báo và Icon Menu 3 gạch chuẩn Apple HIG (>= 44x44dp).
class SenHongSmartHeaderBar extends StatefulWidget {
  final VoidCallback? onPasteAi;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final Color backgroundColor;
  final bool hasUnreadNotification;
  final double contentHeight;
  final bool includeTopPadding;
  final List<String> hints;

  static const List<String> defaultHints = [
    'Dán chuyển tiền AI',
    'Hỏi Trợ lý AI Sen Hồng 24/7',
    'Tìm kiếm dịch vụ & tiện ích',
    'Săn ưu đãi Sen Hồng hôm nay',
    'Thanh toán điện, nước, 4G...',
  ];

  const SenHongSmartHeaderBar({
    super.key,
    this.onPasteAi,
    this.onNotificationTap,
    this.onMenuTap,
    this.backgroundColor = const Color(0xFFFAF6EE),
    this.hasUnreadNotification = false,
    this.contentHeight = 44,
    this.includeTopPadding = true,
    this.hints = defaultHints,
  });

  @override
  State<SenHongSmartHeaderBar> createState() => _SenHongSmartHeaderBarState();
}

class _SenHongSmartHeaderBarState extends State<SenHongSmartHeaderBar> {
  int _activeHintIndex = 0;

  Future<void> _handleSearchBoxTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (widget.onPasteAi != null) {
      widget.onPasteAi!();
      return;
    }

    // Mở Modal Bottom Sheet tìm kiếm 100% chuẩn giao diện mẫu
    showSmartSearchModalSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo khoảng cách an toàn dưới Status Bar (đồng hồ, pin, thông báo hệ thống)
    final topPadding = widget.includeTopPadding ? MediaQuery.of(context).padding.top : 0.0;
    final adjustedTop = widget.includeTopPadding
        ? (topPadding > 0 ? topPadding + 6.0 : 8.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.only(top: adjustedTop, bottom: 12),
      decoration: ShapeDecoration(
        color: widget.backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(34),
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        height: widget.contentHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Ô tìm kiếm xoay vòng với viền Gradient chuyển sắc
              Expanded(
                child: Semantics(
                  button: true,
                  label: widget.hints.isNotEmpty ? widget.hints[_activeHintIndex] : 'Tìm kiếm',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleSearchBoxTap(context),
                      borderRadius: BorderRadius.circular(24),
                      child: BorderBeam(
                        borderRadius: 24,
                        strokeWidth: 1.5,
                        duration: const Duration(seconds: 4),
                        beamLength: 0.28,
                        glowSigma: 6.0,
                        glowOpacity: 0.40,
                        colors: const [
                          Color(0xFF00C9A7), // Xanh Ngọc Sen Hồng
                          Color(0xFF3BB2FF), // Xanh Cyan Napas
                          Color(0xFF7C5CFF), // Tím AI Futuristic
                          Color(0xFFFF6BCB), // Hồng Sen Hồng Rose
                        ],
                        baseBorderColor: const Color(0x1A2C3E50),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C9A7).withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Biểu tượng ngôi sao AI ✨ gradient xanh
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF14B885), Color(0xFF06B6D4)],
                                ).createShader(bounds),
                                child: const Icon(
                                  CupertinoIcons.sparkles,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Văn bản gợi ý xoay vòng mượt mà
                              Expanded(
                                child: AnimatedHintTicker(
                                  hints: widget.hints,
                                  onIndexChanged: (idx) {
                                    _activeHintIndex = idx;
                                  },
                                  textStyle: const TextStyle(
                                    color: Color(0xFF555555),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Biểu tượng Dán (hai trang tài liệu 📋) chuẩn MB Bank
                              const Icon(
                                CupertinoIcons.doc_on_clipboard,
                                size: 18,
                                color: Color(0xFF8A94A6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Icon Chuông thông báo
              Semantics(
                button: true,
                label: 'Thông báo',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          if (widget.onNotificationTap != null) {
                            widget.onNotificationTap!();
                          } else {
                            context.push('/notifications');
                          }
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF2C3E50),
                          size: 26,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                      if (widget.hasUnreadNotification)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Icon Menu 3 gạch
              Semantics(
                button: true,
                label: 'Danh mục mở rộng',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (widget.onMenuTap != null) {
                        widget.onMenuTap!();
                      } else {
                        context.push('/more');
                      }
                    },
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF2C3E50),
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh công cụ dạng SliverAppBar tự động trượt xuống khi cuộn/vuốt xuống (floating & snap).
class SenHongSmartSliverAppBar extends StatelessWidget {
  final VoidCallback? onPasteAi;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final Color backgroundColor;
  final bool hasUnreadNotification;
  final double toolbarHeight;
  final List<String> hints;

  const SenHongSmartSliverAppBar({
    super.key,
    this.onPasteAi,
    this.onNotificationTap,
    this.onMenuTap,
    this.backgroundColor = const Color(0xFFFAF6EE),
    this.hasUnreadNotification = false,
    this.toolbarHeight = 62,
    this.hints = SenHongSmartHeaderBar.defaultHints,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
        ),
      ),
      titleSpacing: 0,
      title: SenHongSmartHeaderBar(
        onPasteAi: onPasteAi,
        onNotificationTap: onNotificationTap,
        onMenuTap: onMenuTap,
        backgroundColor: Colors.transparent,
        hasUnreadNotification: hasUnreadNotification,
        contentHeight: toolbarHeight,
        includeTopPadding: false,
        hints: hints,
      ),
    );
  }
}
