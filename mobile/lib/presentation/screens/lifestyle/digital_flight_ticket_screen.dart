import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Vé Máy Bay Số - Tra cứu chuyến bay, vé điện tử & check-in online
class DigitalFlightTicketScreen extends StatefulWidget {
  const DigitalFlightTicketScreen({super.key});

  @override
  State<DigitalFlightTicketScreen> createState() =>
      _DigitalFlightTicketScreenState();
}

class _DigitalFlightTicketScreenState extends State<DigitalFlightTicketScreen> {
  int _activeTab = 0; // 0: Tìm vé máy bay số, 1: Vé điện tử của tôi
  String _originCode = 'SGN';
  String _originName = 'TP. Hồ Chí Minh';
  String _destCode = 'HAN';
  String _destName = 'Hà Nội';
  final int _passengers = 1;

  final List<Map<String, dynamic>> _availableFlights = [
    {
      'airline': 'Vietnam Airlines',
      'flightNo': 'VN-242',
      'depart': '06:30',
      'arrive': '08:45',
      'duration': '2h 15m',
      'price': 1450000,
      'tier': 'Phổ thông Tiêu chuẩn',
      'miles': '+1.450 dặm Lotusmiles',
      'luggage': '23kg ký gửi + 12kg xách tay',
    },
    {
      'airline': 'Bamboo Airways',
      'flightNo': 'QH-204',
      'depart': '09:15',
      'arrive': '11:25',
      'duration': '2h 10m',
      'price': 1320000,
      'tier': 'Bamboo Economy',
      'miles': '+1.320 dặm Club',
      'luggage': '20kg ký gửi + 7kg xách tay',
    },
    {
      'airline': 'Vietjet Air',
      'flightNo': 'VJ-182',
      'depart': '13:00',
      'arrive': '15:10',
      'duration': '2h 10m',
      'price': 980000,
      'tier': 'Eco Saver',
      'miles': '+980 dặm SkyJoy',
      'luggage': '7kg xách tay',
    },
  ];

  void _swapAirports() {
    HapticFeedback.selectionClick();
    setState(() {
      final tmpCode = _originCode;
      final tmpName = _originName;
      _originCode = _destCode;
      _originName = _destName;
      _destCode = tmpCode;
      _destName = tmpName;
    });
  }

  void _bookFlight(Map<String, dynamic> flight) {
    HapticFeedback.mediumImpact();
    final total = (flight['price'] as int) * _passengers;

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
              const Icon(CupertinoIcons.airplane,
                  size: 54, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'XÁC NHẬN VÉ MÁY BAY SỐ',
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
                    _buildTicketRow('Chặng bay', '$_originCode ➔ $_destCode'),
                    const Divider(height: 16),
                    _buildTicketRow(
                        'Hãng hàng không', flight['airline'] as String),
                    const Divider(height: 16),
                    _buildTicketRow('Chuyến bay',
                        '${flight['flightNo']} (${flight['depart']} - ${flight['arrive']})'),
                    const Divider(height: 16),
                    _buildTicketRow('Hành khách', '$_passengers người lớn'),
                    const Divider(height: 16),
                    _buildTicketRow(
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
                        setState(() => _activeTab = 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '🎉 Xuất vé máy bay số thành công! Xem thẻ lên tàu bay điện tử (E-ticket) bên dưới.'),
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
                      child: const Text('Xác nhận & Xuất vé',
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

  Widget _buildTicketRow(String title, String val, {bool isHighlight = false}) {
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
          'Vé Máy Bay Số',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3), width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.qrcode_viewfinder,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'E-Ticket IATA',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Switcher tab Tìm vé vs Vé của tôi
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeTab = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Săn vé số điện tử',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _activeTab == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _activeTab == 0
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeTab = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Vé của tôi (E-Ticket)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _activeTab == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _activeTab == 1
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_activeTab == 0) ...[
            // Hộp tìm kiếm chặng bay
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.06), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nơi đi',
                                    style: AppTypography.bodySmall(
                                        color: const Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                Text(
                                  _originCode,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B)),
                                ),
                                Text(_originName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _swapAirports,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 0.8),
                              ),
                              child: const Icon(
                                  CupertinoIcons.arrow_right_arrow_left,
                                  size: 18,
                                  color: AppColors.primary),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Nơi đến',
                                    style: AppTypography.bodySmall(
                                        color: const Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                Text(
                                  _destCode,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B)),
                                ),
                                Text(_destName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 8,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.calendar,
                                  size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text('Khởi hành: Hôm nay',
                                  style: AppTypography.bodySmall(
                                          color: const Color(0xFF334155))
                                      .copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.person_2,
                                  size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text('$_passengers Hành khách',
                                  style: AppTypography.bodySmall(
                                          color: const Color(0xFF334155))
                                      .copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Danh sách các chuyến bay khả dụng
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Các chuyến bay số trực tuyến trong ngày',
                  style:
                      AppTypography.bodyMedium(color: const Color(0xFF1E293B))
                          .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final flight = _availableFlights[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                              width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        flight['flightNo'] as String,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      flight['airline'] as String,
                                      style: AppTypography.bodySmall(
                                              color: const Color(0xFF1E293B))
                                          .copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Flexible(
                                    child: Text(
                                  flight['miles'] as String,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF059669)),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(flight['depart'] as String,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B))),
                                    Text(_originCode,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B))),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(flight['duration'] as String,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8))),
                                    Container(
                                      width: 80,
                                      height: 1,
                                      color: const Color(0xFFCBD5E1),
                                    ),
                                    const Text('Bay thẳng',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B))),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(flight['arrive'] as String,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B))),
                                    Text(_destCode,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B))),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${CurrencyFormatter.format(flight['price'])} đ',
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () => _bookFlight(flight),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Chọn vé',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _availableFlights.length,
                ),
              ),
            ),
          ] else ...[
            // Tab Vé điện tử của tôi (E-Ticket Boarding Pass thực tế)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.06), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.airplane,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'BOARDING PASS',
                                style: AppTypography.titleSmall(
                                        color: const Color(0xFF1E293B))
                                    .copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ĐÃ XÁC NHẬN',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('HÀNH KHÁCH',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          Text('NGUYEN VAN A',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CHUYẾN BAY / GHẾ',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          Text('VN-242 • Ghế 14A',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CỬA RA MÁY BAY',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          Text('Gate 12 • Ga T1',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                      const Divider(height: 28),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.black.withOpacity(0.08)),
                              ),
                              child: const Icon(CupertinoIcons.qrcode,
                                  size: 100, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Quét mã QR tại cửa kiểm soát an ninh sân bay',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Đệm 110dp chống cấn Bottom Bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }
}
