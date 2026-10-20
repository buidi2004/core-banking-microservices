import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sen_hong_bank/presentation/widgets/app_morph_icon.dart';
import 'package:morphnext/morphnext.dart';

/// Thẻ tài khoản ngân hàng chuẩn quốc tế (SenBank Premier Card)
/// Thiết kế chuẩn Digital Banking: Chi tiết tài khoản, số dư định dạng tài chính,
/// chip kim loại EMV, sóng NFC, logo hoa sen chìm và 4 nút thao tác nhanh hiện đại.
class BalanceCard extends StatelessWidget {
  final double balance;
  final bool isHidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onTransfer;
  final VoidCallback onQr;

  final String? accountNumber;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isHidden,
    required this.onToggleVisibility,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onTransfer,
    required this.onQr,
    this.accountNumber,
  });

  // Cache formatter — tạo một lần, dùng lại mọi lần build
  static final _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final displayAmount = isHidden ? '••••••••' : _currencyFormatter.format(balance);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF071E3D), // Midnight Navy
            Color(0xFF0F3E6D), // Royal Sapphire
            Color(0xFF056676), // Deep Oceanic Cyan
            Color(0xFF0096C7), // SenBank Vivid Teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071E3D).withOpacity(0.38),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF0096C7).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [


            // 2. VỆT SÁNG NGHỆ THUẬT GÓC TRÊN TRÁI
            Positioned(
              left: -40,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. NỘI DUNG CHÍNH CỦA THẺ
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HÀNG 1: THÔNG TIN TÀI KHOẢN & HUY HIỆU SENBANK PREMIER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chip chip EMV + Sóng NFC + Loại tài khoản
                      Row(
                        children: [
                          // Chip EMV kim loại mạ vàng
                          Container(
                            width: 30,
                            height: 22,
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
                            size: 16,
                            color: Colors.white54,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD54F).withOpacity(0.4),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // HÀNG 2: SỐ TÀI KHOẢN VỚI NÚT SAO CHÉP NHANH
                  Row(
                    children: [
                      Text(
                        'STK:',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          final numToCopy = (accountNumber != null && accountNumber!.isNotEmpty) ? accountNumber! : '';
                          if (numToCopy.isEmpty) return;
                          Clipboard.setData(ClipboardData(text: numToCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Đã sao chép số tài khoản: $numToCopy',
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
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (accountNumber != null && accountNumber!.isNotEmpty) ? accountNumber! : 'Ví Sen Hồng',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                CupertinoIcons.doc_on_doc,
                                color: Colors.white70,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Nhãn số dư khả dụng + Mắt ẩn hiện
                      Row(
                        children: [
                          Text(
                            'Khả dụng',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onToggleVisibility();
                            },
                            child: AppMorphIcon(
                              icon: isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 16,
                              color: Colors.white70,
                              spring: MorphSprings.snappy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // HÀNG 3: SỐ TIỀN HIỂN THỊ CHUẨN TYPOGRAPHY TÀI CHÍNH
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayAmount,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'VND',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF26E5DC), // Cyan highlight
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ĐƯỜNG PHÂN TÁCH MỜ
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.12),
                  ),

                  const SizedBox(height: 14),

                  // HÀNG 4: 4 NÚT THAO TÁC NHANH CHUẨN NGÂN HÀNG SỐ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBankingActionButton(
                        icon: CupertinoIcons.paperplane_fill,
                        label: 'Chuyển tiền',
                        onTap: onTransfer,
                      ),
                      _buildBankingActionButton(
                        icon: CupertinoIcons.arrow_down_circle_fill,
                        label: 'Nạp tiền',
                        onTap: onDeposit,
                      ),
                      _buildBankingActionButton(
                        icon: CupertinoIcons.arrow_up_circle_fill,
                        label: 'Rút tiền',
                        onTap: onWithdraw,
                      ),
                      _buildBankingActionButton(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        label: 'Mã QR',
                        onTap: onQr,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.32),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
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
