import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Vé máy bay đối tác iMedia - Đặt vé máy bay nội địa & quốc tế giá tốt
class ImediaFlightScreen extends StatefulWidget {
  const ImediaFlightScreen({super.key});

  @override
  State<ImediaFlightScreen> createState() => _ImediaFlightScreenState();
}

class _ImediaFlightScreenState extends State<ImediaFlightScreen> {
  bool _addInsurance = true;
  bool _addExtraBaggage = false;

  final List<Map<String, dynamic>> _deals = [
    {
      'airline': 'Vietnam Airlines',
      'route': 'TP.HCM ➔ Phú Quốc (PQC)',
      'code': 'VN-1823',
      'depart': '07:15',
      'price': 890000,
      'discount': '-15%',
    },
    {
      'airline': 'Singapore Airlines',
      'route': 'TP.HCM ➔ Singapore (SIN)',
      'code': 'SQ-173',
      'depart': '12:20',
      'price': 2350000,
      'discount': '-10%',
    },
    {
      'airline': 'Vietjet Air',
      'route': 'Hà Nội ➔ Đà Nẵng (DAD)',
      'code': 'VJ-512',
      'depart': '16:40',
      'price': 690000,
      'discount': '-20%',
    },
    {
      'airline': 'All Nippon Airways (ANA)',
      'route': 'Hà Nội ➔ Tokyo (NRT)',
      'code': 'NH-898',
      'depart': '23:30',
      'price': 6800000,
      'discount': '-5%',
    },
  ];

  void _bookDeal(Map<String, dynamic> deal) {
    HapticFeedback.mediumImpact();
    int total = deal['price'] as int;
    if (_addInsurance) total += 55000;
    if (_addExtraBaggage) total += 180000;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(CupertinoIcons.paperplane_fill,
                  size: 54, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'ĐẶT VÉ QUA iMEDIA',
                style: AppTypography.titleMedium(
                  color: const Color(0xFF1E293B),
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Chặng bay', deal['route'] as String),
                    const Divider(height: 16),
                    _buildSummaryRow('Hãng / Chuyến bay',
                        '${deal['airline']} (${deal['code']})'),
                    const Divider(height: 16),
                    _buildSummaryRow('Giờ cất cánh', deal['depart'] as String),
                    if (_addInsurance) ...[
                      const Divider(height: 16),
                      _buildSummaryRow('Bảo hiểm trễ chuyến', '55.000 đ'),
                    ],
                    if (_addExtraBaggage) ...[
                      const Divider(height: 16),
                      _buildSummaryRow('Hành lý thêm 20kg', '180.000 đ'),
                    ],
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Tổng thanh toán',
                      '${CurrencyFormatter.format(total)} đ',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '🎉 Giữ chỗ vé máy bay iMedia thành công! Hóa đơn & vé điện tử đã gửi tới bạn.'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Thanh toán an toàn',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String title, String val,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: AppTypography.bodySmall(color: const Color(0xFF64748B))),
        Text(
          val,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDF9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: Color(0xFF1E293B)),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
        title: Text(
          'Vé máy bay',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
            ),
            child: const Text(
              'iMedia Travel',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Banner ưu đãi độc quyền đối tác iMedia
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(CupertinoIcons.ticket_fill,
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ƯU ĐÃI ĐỘC QUYỀN iMEDIA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giảm ngay tới 20% các chặng bay hot',
                            style: AppTypography.titleSmall(
                                    color: const Color(0xFF1E293B))
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Áp dụng cho mọi chủ tài khoản Sen Hồng Bank',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lựa chọn tiện ích bổ trợ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiện ích chuyến bay cộng thêm',
                      style: AppTypography.bodySmall(
                              color: const Color(0xFF1E293B))
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: _addInsurance,
                        onChanged: (val) =>
                            setState(() => _addInsurance = val ?? false),
                        title: const Text(
                            'Bảo hiểm trễ chuyến bay iMedia Care (+55.000 đ)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Tự động bồi thường 500.000 đ/giờ trễ vào tài khoản',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: _addExtraBaggage,
                        onChanged: (val) =>
                            setState(() => _addExtraBaggage = val ?? false),
                        title: const Text(
                            'Mua thêm 20kg hành lý ký gửi (+180.000 đ)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Tiết kiệm 40% so với mua trực tiếp tại quầy sân bay',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Danh sách chặng bay giá tốt iMedia
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                'Top chặng bay giá tốt nhất trong tuần',
                style: AppTypography.bodyMedium(color: const Color(0xFF1E293B))
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final deal = _deals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.06), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      deal['route'] as String,
                                      style: AppTypography.bodyMedium(
                                              color: const Color(0xFF1E293B))
                                          .copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        deal['discount'] as String,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${deal['airline']} • Chuyến ${deal['code']} • Khởi hành ${deal['depart']}',
                                  style: AppTypography.bodySmall(
                                      color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${CurrencyFormatter.format(deal['price'])} đ',
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FilledButton(
                                onPressed: () => _bookDeal(deal),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Đặt vé',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _deals.length,
              ),
            ),
          ),

          // Đệm 110dp chống cấn Bottom Bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }
}
