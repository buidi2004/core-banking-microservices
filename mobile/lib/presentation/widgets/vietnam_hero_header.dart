import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'user_avatar_widget.dart';
import 'package:sen_hong_bank/presentation/widgets/app_morph_icon.dart';
import 'package:morphnext/morphnext.dart';

/// Header Lễ hội SenBank:
/// - Toàn bộ thông tin tài khoản (Lời chào, STK, Chip EMV, Số dư 12.580.000 VND) hiển thị trên banner
/// - Tòa nhà SenBank, hoa sen vàng và quảng trường thông thoáng, trọn vẹn không bị che khuất
class VietnamHeroHeader extends StatelessWidget {
  final double balance;
  final bool isHidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onTransfer;
  final VoidCallback? onQr;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final String displayName;
  final String accountNumber;

  const VietnamHeroHeader({
    super.key,
    required this.balance,
    required this.isHidden,
    required this.onToggleVisibility,
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
    final displayAmount = isHidden ? '••••••••' : _currencyFormatter.format(balance);
    final bannerHeight = 355.0 + topPadding;

    return SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. PHÔNG NỀN LÀM MỜ TỐI ƯU TUYỆT ĐỐI (ẢNH BANNER + LỚP PHỦ CHỮ ĐỀU FADE OUT MỊN MÀNG)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,       // 0% -> 50%: Giữ 100% độ rõ cho thông tin và kiến trúc
                    Colors.black,
                    Color(0xF5000000),  // 60%: Bắt đầu chuyển tiếp siêu êm
                    Color(0xD8000000),  // 70%
                    Color(0xA0000000),  // 78%
                    Color(0x60000000),  // 86%
                    Color(0x28000000),  // 93%
                    Color(0x0A000000),  // 97%
                    Colors.transparent, // 100%: Hoàn toàn trong suốt, hòa tan mượt mà vào nền kính
                  ],
                  stops: [0.0, 0.50, 0.60, 0.70, 0.78, 0.86, 0.93, 0.97, 1.0],
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
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
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
                              Positioned(
                                right: 3,
                                top: 3,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 38,
                            height: 38,
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
                        ],
                      ),

                      // Cụm Lời chào & Avatar (sát lề phải)
                      InkWell(
                        onTap: onProfileTap,
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                  displayName.isEmpty ? 'Chưa có thông tin' : displayName,
                                  style: GoogleFonts.plusJakartaSans(
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
                            const SizedBox(width: 10),
                            const UserAvatarWidget(
                              radius: 19,
                              borderColor: Color(0xFFFFD54F),
                              borderWidth: 1.5,
                              showBorder: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // HÀNG 2: CHIP EMV + TK THANH TOÁN & HUY HIỆU SENBANK PREMIER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Chip EMV kim loại mạ vàng
                          Container(
                            width: 28,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFDF7A),
                                  Color(0xFFD4AF37),
                                  Color(0xFFAA771C),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: const Color(0xFF8B6508),
                                width: 0.5,
                              ),
                            ),
                            child: CustomPaint(painter: _EmvChipPainter()),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.radiowaves_right,
                            size: 15,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TK THANH TOÁN',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),

                      // Huy hiệu SenBank Premier
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD54F).withOpacity(0.6),
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
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFFFE082),
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
                      _CopyStkChip(accountNumber: accountNumber),
                      const Spacer(),
                      // Khả dụng + Icon Mắt
                      InkWell(
                        onTap: onToggleVisibility,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                icon: isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF26E5DC), // Cyan highlight
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

                ],
              ),
            ),
          ],
        ),
      );
  }
}

/// CustomPainter vẽ các vân rãnh vi mạch chip thông minh EMV
class _EmvChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B6508).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // Đường phân cách vi mạch trung tâm
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.45, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.38),
      Offset(size.width, size.height * 0.38),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Đã sao chép STK: ${widget.accountNumber}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F3E6D),
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
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: _copied ? const Color(0xFF26E5DC).withOpacity(0.18) : Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _copied ? const Color(0xFF26E5DC).withOpacity(0.8) : Colors.white.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.accountNumber.isEmpty ? 'Chưa có số tài khoản' : widget.accountNumber,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 5),
            AppMorphIcon(
              icon: _copied ? Icons.check_circle_rounded : Icons.content_copy_rounded,
              color: _copied ? const Color(0xFF26E5DC) : Colors.white70,
              size: 13,
              spring: MorphSprings.snappy,
            ),
          ],
        ),
      ),
    );
  }
}
