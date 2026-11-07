import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'user_avatar_widget.dart';
import 'package:sen_hong_bank/presentation/widgets/app_morph_icon.dart';
import 'package:morphnext/morphnext.dart';
import '../../core/theme/app_colors.dart';

/// Header Lễ hội SenBank:
/// - Toàn bộ thông tin tài khoản (Lời chào, STK, Chip EMV, Số dư 12.580.000 VND) hiển thị trên banner
/// - Tòa nhà SenBank, hoa sen vàng và quảng trường thông thoáng, trọn vẹn không bị che khuất
class VietnamHeroHeader extends StatelessWidget {
  final double balance;
  final bool isHidden;
  final VoidCallback onToggleVisibility;

  /// Hạn mức thấu chi cấp cho ví (tính năng 4.1). 0 = không thấu chi.
  final double overdraftLimit;

  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onTransfer;
  final VoidCallback? onQr;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final String displayName;
  final String accountNumber;
  final int unreadCount;

  const VietnamHeroHeader({
    super.key,
    required this.balance,
    required this.isHidden,
    required this.onToggleVisibility,
    this.overdraftLimit = 0,
    this.unreadCount = 0,
    this.onDeposit,
    this.onWithdraw,
    this.onTransfer,
    this.onQr,
    this.onNotificationTap,
    this.onSearchTap,
    this.onProfileTap,
    this.displayName = '',
    this.accountNumber = '',
  });
  // Cache formatter — tạo một lần, dùng lại mọi lần build
  static final _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final displayAmount =
        isHidden ? '••••••••' : _currencyFormatter.format(balance);
    final bannerHeight = 300.0 + topPadding;

    return Container(
      height: bannerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF041E3A),
            const Color(0xFF0A2E50),
            const Color(0xFF0E4D7A),
            const Color(0xFF0E4D7A).withOpacity(0.95), // 85% opacity
            const Color(0xFF0E4D7A).withOpacity(0.85), // 70% opacity
            const Color(0xFF0E4D7A).withOpacity(0.70), // 50% opacity
            const Color(0xFF0E4D7A).withOpacity(0.50), // 30% opacity
            const Color(0xFF0E4D7A).withOpacity(0.30), // 15% opacity
            const Color(0xFF0E4D7A).withOpacity(0.15), // 8% opacity
            Colors.transparent, // Hoàn toàn trong suốt
          ],
          stops: const [
            0.0,
            0.35,
            0.50,
            0.60,
            0.68,
            0.76,
            0.84,
            0.90,
            0.95,
            1.0
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. PHÔNG NỀN LÀM MỜ TỐI ƯU TUYỆT ĐỐI (ẢNH BANNER + LỚP PHỦ CHỮ ĐỀU FADE OUT MỊN MÀNG)
          // TỐI ƯU: Gradient hoà trộn mượt hơn với nền trắng, không bị đứt đoạn
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black, // 0% - 45%: Giữ nguyên độ rõ
                    Colors.black, // 45%: Vẫn giữ 100%
                    Colors.black.withOpacity(
                        0.85), // 55%: 85% opacity - chuyển tiếp mượt
                    Colors.black.withOpacity(0.70), // 65%: 70% opacity
                    Colors.black.withOpacity(0.50), // 75%: 50% opacity
                    Colors.black.withOpacity(0.30), // 85%: 30% opacity
                    Colors.black.withOpacity(0.15), // 92%: 15% opacity
                    Colors.black.withOpacity(0.08), // 96%: 8% opacity
                    Colors.transparent, // 100%: Hoàn toàn trong suốt
                  ],
                  stops: const [
                    0.0,
                    0.35,
                    0.45,
                    0.55,
                    0.65,
                    0.75,
                    0.84,
                    0.92,
                    1.0
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/senbank_hero_banner.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  // Lớp phủ tối nhẹ chỉ ở nửa trên cho chữ, biến mất hoàn toàn ở nửa dưới
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.42),
                          Colors.black.withOpacity(0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.62],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. NỘI DUNG TÀI KHOẢN Ở NỬA TRÊN (Không che tòa nhà hay quảng trường)
          Positioned(
            top: topPadding + 10,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // HÀNG 1: THÔNG BÁO & TÌM KIẾM (TRÁI) & LỜI CHÀO + AVATAR (PHẢI)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cụm Nút chuông thông báo & Tìm kiếm (bên trái)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                tooltip: 'Thông báo',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  onNotificationTap?.call();
                                },
                                icon: const Icon(
                                  CupertinoIcons.bell_fill,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            tooltip: 'Tìm kiếm',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onSearchTap?.call();
                            },
                            icon: const Icon(
                              CupertinoIcons.search,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                        if (onQr != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: 'Quét mã QR',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onQr?.call();
                              },
                              icon: const Icon(
                                CupertinoIcons.qrcode_viewfinder,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(width: 8),
                    // Cụm Lời chào & Avatar (sát lề phải)
                    Expanded(
                      child: InkWell(
                        onTap: onProfileTap,
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Xin chào,',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    displayName.isEmpty
                                        ? 'Chưa có thông tin'
                                        : displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const UserAvatarWidget(
                              radius: 19,
                              borderColor: AppColors.bottomBarCyan,
                              borderWidth: 1.5,
                              showBorder: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // HÀNG 2: CHIP EMV + TK THANH TOÁN & HUY HIỆU SENBANK PREMIER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.creditcard_fill,
                            size: 18,
                            color: AppColors.bottomBarCyan,
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.radiowaves_right,
                            size: 15,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'TK THANH TOÁN',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Huy hiệu SenBank Premier
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.bottomBarCyan.withOpacity(0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/senbank_lotus_isolated.png',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SenBank Premier',
                            style: GoogleFonts.inter(
                              color: AppColors.bottomBarCyan,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // HÀNG 3: SỐ TÀI KHOẢN VỚI NÚT SAO CHÉP NHANH & MẮT ẨN/HIỆN
                Row(
                  children: [
                    Text(
                      'STK:',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(child: _CopyStkChip(accountNumber: accountNumber)),
                    const Spacer(),
                    // Khả dụng + Icon Mắt
                    InkWell(
                      onTap: onToggleVisibility,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              'Khả dụng',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppMorphIcon(
                              icon: isHidden
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              size: 16,
                              color: Colors.white,
                              spring: MorphSprings.snappy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // HÀNG 4: SỐ TIỀN HIỂN THỊ CHUẨN TYPOGRAPHY TÀI CHÍNH
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      displayAmount,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'VND',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bottomBarCyan, // Cyan highlight
                        letterSpacing: 0.8,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // HÀNG 5: CHIP HẠN MỨC THẤU CHI (tính năng 4.1)
                if (overdraftLimit > 0 && !isHidden) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: balance < 0
                            ? const Color(0xFFF59E0B).withOpacity(0.55)
                            : AppColors.bottomBarCyan.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          balance < 0
                              ? CupertinoIcons.exclamationmark_circle_fill
                              : CupertinoIcons.arrow_down_right_circle_fill,
                          size: 13,
                          color: balance < 0
                              ? const Color(0xFFF59E0B) // Amber — đang dư nợ
                              : AppColors.bottomBarCyan,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          balance < 0
                              ? 'Dư nợ thấu chi ${_currencyFormatter.format(-balance)} VND — khả dụng ${_currencyFormatter.format(balance + overdraftLimit)} VND'
                              : 'Hạn mức thấu chi: ${_currencyFormatter.format(overdraftLimit)} VND',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút sao chép STK với hiệu ứng vector morphicon (sao chép <-> checkmark)
class _CopyStkChip extends StatefulWidget {
  final String accountNumber;
  const _CopyStkChip({required this.accountNumber});

  @override
  State<_CopyStkChip> createState() => _CopyStkChipState();
}

class _CopyStkChipState extends State<_CopyStkChip> {
  bool _copied = false;

  void _copy() {
    if (widget.accountNumber.isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.accountNumber));
    HapticFeedback.selectionClick();
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Đã sao chép STK: ${widget.accountNumber}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.brandNavy,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _copied
              ? AppColors.bottomBarCyan.withOpacity(0.18)
              : Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _copied
                ? AppColors.bottomBarCyan.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.accountNumber.isEmpty
                    ? 'Chưa có số tài khoản'
                    : widget.accountNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 5),
            AppMorphIcon(
              icon: _copied
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.doc_on_doc_fill,
              color: _copied ? AppColors.bottomBarCyan : Colors.white70,
              size: 13,
              spring: MorphSprings.snappy,
            ),
          ],
        ),
      ),
    );
  }
}
