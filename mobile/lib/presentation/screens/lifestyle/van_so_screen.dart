import 'dart:math';
import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

/// Màn hình Vận Số & Phong Thủy Tài Lộc - Xem ngày hoàng đạo, giờ tài lộc, số đẹp hợp mệnh & gieo quẻ kinh doanh
class VanSoScreen extends StatefulWidget {
  const VanSoScreen({super.key});

  @override
  State<VanSoScreen> createState() => _VanSoScreenState();
}

class _VanSoScreenState extends State<VanSoScreen> {
  int _selectedBirthYear = 1992;
  bool _isTossingCoins = false;
  int _tossCount = 0;
  String _fortuneTitle = 'Quẻ Thuần Càn (Nguyên Hanh Lợi Trinh)';
  String _fortuneAdvice =
      'Thời vận hanh thông, công việc làm ăn gặp quý nhân phù trợ. Rất thích hợp để mở tài khoản mới, ký kết hợp đồng thương mại lớn hoặc mở rộng quy mô kinh doanh.';

  final List<int> _years = List.generate(45, (i) => 1970 + i);

  final Map<int, Map<String, dynamic>> _menhData = {
    1988: {
      'canChi': 'Mậu Thìn',
      'menh': 'Đại Lâm Mộc',
      'numbers': '3, 4, 1',
      'colors': 'Xanh lục, Xanh lam',
      'element': 'Mộc'
    },
    1989: {
      'canChi': 'Kỷ Tỵ',
      'menh': 'Đại Lâm Mộc',
      'numbers': '3, 4, 1',
      'colors': 'Xanh lục, Đen',
      'element': 'Mộc'
    },
    1990: {
      'canChi': 'Canh Ngọ',
      'menh': 'Lộ Bàng Thổ',
      'numbers': '2, 5, 8, 9',
      'colors': 'Vàng, Nâu, Đỏ',
      'element': 'Thổ'
    },
    1991: {
      'canChi': 'Tân Mùi',
      'menh': 'Lộ Bàng Thổ',
      'numbers': '2, 5, 8, 9',
      'colors': 'Vàng, Nâu, Cam',
      'element': 'Thổ'
    },
    1992: {
      'canChi': 'Nhâm Thân',
      'menh': 'Kiếm Phong Kim',
      'numbers': '6, 7, 2, 8',
      'colors': 'Trắng, Xám, Vàng',
      'element': 'Kim'
    },
    1993: {
      'canChi': 'Quý Dậu',
      'menh': 'Kiếm Phong Kim',
      'numbers': '6, 7, 2, 8',
      'colors': 'Trắng, Ánh kim',
      'element': 'Kim'
    },
    1994: {
      'canChi': 'Giáp Tuất',
      'menh': 'Sơn Đầu Hỏa',
      'numbers': '9, 3, 4',
      'colors': 'Đỏ, Tím, Xanh lá',
      'element': 'Hỏa'
    },
    1995: {
      'canChi': 'Ất Hợi',
      'menh': 'Sơn Đầu Hỏa',
      'numbers': '9, 3, 4',
      'colors': 'Đỏ, Hồng, Xanh lá',
      'element': 'Hỏa'
    },
    1996: {
      'canChi': 'Bính Tý',
      'menh': 'Giản Hạ Thủy',
      'numbers': '1, 6, 7',
      'colors': 'Xanh dương, Trắng, Đen',
      'element': 'Thủy'
    },
    1997: {
      'canChi': 'Đinh Sửu',
      'menh': 'Giản Hạ Thủy',
      'numbers': '1, 6, 7',
      'colors': 'Xanh biển, Trắng bạc',
      'element': 'Thủy'
    },
    1998: {
      'canChi': 'Mậu Dần',
      'menh': 'Thành Đầu Thổ',
      'numbers': '2, 5, 8, 9',
      'colors': 'Nâu đất, Vàng kim',
      'element': 'Thổ'
    },
    1999: {
      'canChi': 'Kỷ Mão',
      'menh': 'Thành Đầu Thổ',
      'numbers': '2, 5, 8, 9',
      'colors': 'Vàng sẫm, Đỏ nhạt',
      'element': 'Thổ'
    },
    2000: {
      'canChi': 'Canh Thìn',
      'menh': 'Bạch Lạp Kim',
      'numbers': '6, 7, 2, 8',
      'colors': 'Trắng, Ghi xám',
      'element': 'Kim'
    },
  };

  void _tossIChingCoins() {
    if (_isTossingCoins) return;
    HapticFeedback.heavyImpact();
    setState(() => _isTossingCoins = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      final fortunes = [
        {
          'title': 'Quẻ Thuần Càn (Đại Cát Đại Lợi)',
          'advice':
              'Vận khí cực thịnh, tiền tài sinh sôi nảy nở. Thích hợp xuất tiền đầu tư sinh lời và mở rộng kinh doanh.',
        },
        {
          'title': 'Quẻ Địa Thiên Thái (Thông Suốt Hanh Thông)',
          'advice':
              'Thượng hạ hòa mục, tài lộc tự tìm đến cửa. Những kế hoạch tài chính đã ấp ủ nay là thời cơ vàng để khởi động.',
        },
        {
          'title': 'Quẻ Hỏa Thiên Đại Hữu (Của Cải Dồi Dào)',
          'advice':
              'Tài khí ngập tràn, được sự tín nhiệm lớn từ đối tác. Nên duy trì chữ tín và tích lũy tiết kiệm bền vững.',
        },
        {
          'title': 'Quẻ Thủy Địa Tỷ (Gắn Kết Thân Tình)',
          'advice':
              'Kinh doanh nhờ bạn bè, đối tác đắc lực hỗ trợ. Thuận lợi cho việc hùn vốn đầu tư cùng người đồng hành.',
        },
      ];

      final res = fortunes[Random().nextInt(fortunes.length)];
      if (!mounted) return;
      setState(() {
        _isTossingCoins = false;
        _tossCount++;
        _fortuneTitle = res['title']!;
        _fortuneAdvice = res['advice']!;
      });
      HapticFeedback.mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = _menhData[_selectedBirthYear] ??
        {
          'canChi': 'Canh Ngọ',
          'menh': 'Bản Mệnh Cát Tường',
          'numbers': '6, 8, 9',
          'colors': 'Vàng kim, Trắng tinh khôi',
          'element': 'Kim',
        };

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
          'Vận Số & Phong Thủy',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B), width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.sun_max_fill,
                    size: 14, color: Color(0xFFB45309)),
                SizedBox(width: 4),
                Text(
                  'Hoàng Đạo',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Card Khí vận hôm nay (Lịch vạn niên & Giờ hoàng đạo tài lộc)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LỊCH VẠN NIÊN HÔM NAY',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                  letterSpacing: 0.8),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ngày Bính Thìn • Tháng Mậu Tuất',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B)),
                            ),
                          ],
                        )),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black.withOpacity(0.06)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('☯',
                              style: TextStyle(
                                  fontSize: 24, color: Color(0xFF1E293B))),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildFengShuiRow('Trực ngày',
                        'Trực Khai (Rất tốt cho mở hàng, khai trương, mở sổ tiết kiệm)'),
                    const SizedBox(height: 8),
                    _buildFengShuiRow('Giờ tốt xuất tiền',
                        'Thìn (7-9h), Tỵ (9-11h), Thân (15-17h), Dậu (17-19h)'),
                    const SizedBox(height: 8),
                    _buildFengShuiRow('Hướng đón Tài Thần',
                        'Chính Đông (Đón tài lộc đại cát đại lợi)'),
                  ],
                ),
              ),
            ),
          ),

          // Khối Tra cứu Cung Mệnh & Con số tài lộc theo năm sinh
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(
                          'Bản Mệnh & Số Tài Lộc',
                          style: AppTypography.titleSmall(
                                  color: const Color(0xFF1E293B))
                              .copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        )),
                        DropdownButton<int>(
                          value: _selectedBirthYear,
                          underline: const SizedBox(),
                          items: _years
                              .map((y) =>
                                  DropdownMenuItem(value: y, child: Text('$y')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedBirthYear = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Can Chi / Ngũ Hành',
                                  style: AppTypography.bodySmall(
                                      color: const Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${info['canChi']} • Mệnh ${info['menh']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text('Con số tài lộc hợp mệnh',
                                      style: AppTypography.bodySmall(
                                          color: const Color(0xFF64748B)),
                                      overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Flexible(
                                  child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  info['numbers'] as String,
                                  style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                      fontSize: 13),
                                ),
                              )),
                            ],
                          ),
                          const Divider(height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 170,
                                child: Text('Màu sắc may mắn sinh tài',
                                    style: AppTypography.bodySmall(
                                        color: const Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(
                                info['colors'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/lucky-account');
                        },
                        icon: const Icon(CupertinoIcons.sparkles, size: 16),
                        label: const Text('Mở tài khoản số đẹp hợp mệnh'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Gieo Quẻ Kinh Dịch May Mắn Tài Chính Hàng Ngày
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                            child: Text(
                          'Gieo Quẻ Tài Lộc Hôm Nay',
                          style: AppTypography.titleSmall(
                                  color: const Color(0xFF1E293B))
                              .copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        )),
                        const SizedBox(width: 8),
                        Text('Lần gieo: $_tossCount',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 3 Đồng tiền xu cổ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFD97706), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFD97706).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFD97706), width: 1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.06), width: 0.5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _fortuneTitle,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fortuneAdvice,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(
                                    color: const Color(0xFF475569))
                                .copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _tossIChingCoins,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _isTossingCoins
                              ? 'Đang gieo quẻ may mắn...'
                              : 'Chạm để Gieo quẻ Tài Lộc',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
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

  Widget _buildFengShuiRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
