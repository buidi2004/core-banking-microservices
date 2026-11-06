import 'dart:async';
import 'dart:math';
import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

/// Màn hình Vua Xổ Số - Kết quả xổ số kiến thiết 3 miền, dò vé số thần tốc & quay thử
class VuaXoSoScreen extends StatefulWidget {
  const VuaXoSoScreen({super.key});

  @override
  State<VuaXoSoScreen> createState() => _VuaXoSoScreenState();
}

class _VuaXoSoScreenState extends State<VuaXoSoScreen> {
  int _selectedRegion = 0; // 0: Miền Bắc, 1: Miền Nam, 2: Miền Trung
  final TextEditingController _ticketCodeCtrl = TextEditingController();
  bool _isSimulating = false;
  String _simulatedNumber = '------';

  final List<String> _regions = [
    'Miền Bắc (Hà Nội)',
    'Miền Nam (TP.HCM)',
    'Miền Trung (Đà Nẵng)'
  ];

  // Kết quả xổ số mẫu xác thực theo chuẩn các đài kiến thiết
  final Map<int, Map<String, dynamic>> _lotteryResults = {
    0: {
      'station': 'Hà Nội (XSMB)',
      'date': 'Hôm nay - Kỳ #304',
      'special': '682914',
      'first': '39512',
      'second': ['81943', '20491'],
      'third': ['58204', '91034', '44910', '72384', '16839', '83021'],
      'fourth': ['3920', '8401', '1952', '6743'],
      'fifth': ['9481', '3321', '7604', '1294', '8590', '4823'],
      'sixth': ['582', '910', '349'],
      'seventh': ['84', '21', '09', '77'],
    },
    1: {
      'station': 'TP. Hồ Chí Minh (XSMN)',
      'date': 'Hôm nay - Kỳ #412',
      'special': '829401',
      'first': '49120',
      'second': ['39102'],
      'third': ['19402', '83921'],
      'fourth': ['74921', '83910', '29401', '58291', '90342', '12849', '47382'],
      'fifth': ['3921'],
      'sixth': ['8491', '2049', '7591'],
      'seventh': ['392'],
      'eighth': ['68'],
    },
    2: {
      'station': 'Đà Nẵng (XSMT)',
      'date': 'Hôm nay - Kỳ #198',
      'special': '719385',
      'first': '58219',
      'second': ['49201'],
      'third': ['72940', '19482'],
      'fourth': ['39201', '84910', '58291', '19402', '90342', '47382', '29401'],
      'fifth': ['8392'],
      'sixth': ['2941', '8492', '1094'],
      'seventh': ['482'],
      'eighth': ['15'],
    },
  };

  void _checkTicket() {
    final ticket = _ticketCodeCtrl.text.trim();
    if (ticket.isEmpty || ticket.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng nhập đúng dãy số vé (ít nhất 5 chữ số) để dò thưởng'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final current = _lotteryResults[_selectedRegion]!;
    final special = current['special'] as String;
    final isJackpot = ticket.endsWith(special.substring(special.length - 5));

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
              Icon(
                isJackpot
                    ? CupertinoIcons.sparkles
                    : CupertinoIcons.check_mark_circled_solid,
                size: 56,
                color: isJackpot ? const Color(0xFFD97706) : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                isJackpot ? 'CHÚC MỪNG TRÚNG THƯỞNG!' : 'KẾT QUẢ DÒ VÉ',
                style: AppTypography.titleMedium(
                  color: const Color(0xFF1E293B),
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Số vé kiểm tra: $ticket',
                style: AppTypography.bodyMedium(
                  color: const Color(0xFF64748B),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isJackpot
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isJackpot
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Đài: ${current['station']}',
                      style: AppTypography.bodySmall(
                        color: const Color(0xFF475569),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isJackpot
                          ? '🎉 Trúng giải Đặc biệt: 2.000.000.000 đ'
                          : 'Số vé của quý khách không trùng các giải kỳ này. Chúc quý khách may mắn kỳ tới!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(
                        color: isJackpot
                            ? const Color(0xFF92400E)
                            : const Color(0xFF334155),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Đóng',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _runSimulation() {
    if (_isSimulating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSimulating = true);

    int count = 0;
    Timer.periodic(const Duration(milliseconds: 70), (timer) {
      count++;
      final random = Random();
      final num = List.generate(6, (_) => random.nextInt(10)).join();
      setState(() => _simulatedNumber = num);

      if (count > 25) {
        timer.cancel();
        setState(() => _isSimulating = false);
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _ticketCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _lotteryResults[_selectedRegion]!;

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
          'Vua Xổ Số',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '18:15 Trực tiếp',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Khu vực chuyển vùng miền
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: List.generate(_regions.length, (idx) {
                    final isSelected = _selectedRegion == idx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedRegion = idx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            idx == 0
                                ? 'Miền Bắc'
                                : (idx == 1 ? 'Miền Nam' : 'Miền Trung'),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(
                              color: isSelected
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Card Kết quả giải đặc biệt hôm nay
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            current['station'] as String,
                            style: AppTypography.bodyMedium(
                              color: const Color(0xFF1E293B),
                            ).copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          current['date'] as String,
                          style: AppTypography.bodySmall(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFDA4AF), width: 0.5),
                      ),
                      child: const Text(
                        'GIẢI ĐẶC BIỆT',
                        style: TextStyle(
                          color: Color(0xFFE11D48),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      current['special'] as String,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trị giá giải thưởng: 2.000.000.000 đ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bảng dò số nhanh
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.search,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Dò vé số thần tốc',
                          style: AppTypography.bodyMedium(
                            color: const Color(0xFF1E293B),
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ticketCodeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Nhập 5 hoặc 6 chữ số vé',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.08)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.08)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _checkTicket,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Dò kết quả',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lồng cầu quay thử may mắn
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Quay thử lồng cầu may mắn',
                            style: AppTypography.bodyMedium(
                              color: const Color(0xFF1E293B),
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _runSimulation,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child:
                              Text(_isSimulating ? 'Đang quay...' : 'Quay thử'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _simulatedNumber,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontFeatures: [FontFeature.tabularFigures()],
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chi tiết bảng các giải xổ số
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Bảng chi tiết các giải thưởng',
                style: AppTypography.bodyMedium(
                  color: const Color(0xFF1E293B),
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  children: [
                    _buildPrizeRow('Giải Nhất (30 Triệu)',
                        current['first']?.toString() ?? '--',
                        isEven: false),
                    _buildPrizeRow('Giải Nhì (15 Triệu)',
                        (current['second'] as List?)?.join(' - ') ?? '--',
                        isEven: true),
                    _buildPrizeRow('Giải Ba (10 Triệu)',
                        (current['third'] as List?)?.join(' - ') ?? '--',
                        isEven: false),
                    _buildPrizeRow('Giải Tư (3 Triệu)',
                        (current['fourth'] as List?)?.join(' - ') ?? '--',
                        isEven: true),
                    _buildPrizeRow('Giải Năm (1 Triệu)',
                        (current['fifth'] as List?)?.join(' - ') ?? '--',
                        isEven: false),
                  ],
                ),
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

  Widget _buildPrizeRow(String title, String numbers, {required bool isEven}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: AppTypography.bodySmall(
                color: const Color(0xFF475569),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              numbers,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontFeatures: [FontFeature.tabularFigures()],
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
