import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

/// Màn hình Tất Cả Dịch Vụ & Tiện Ích Số - Trung tâm dịch vụ hệ sinh thái Sen Hồng Bank
class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchKeyword = '';

  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Mua sắm - Giải trí - Đầu tư',
      'items': [
        {
          'name': 'Vua Xổ Số',
          'sub': 'XSMB, XSMN, XSMT trực tiếp',
          'icon': CupertinoIcons.sparkles,
          'color': const Color(0xFFDC2626),
          'route': '/vua-xo-so',
        },
        {
          'name': 'Vé số Vietlott',
          'sub': 'Power 6/55, Mega 6/45, Keno',
          'icon': CupertinoIcons.tickets_fill,
          'color': const Color(0xFFEA580C),
          'route': '/vietlott',
        },
        {
          'name': 'Data 4G / Nạp tiền',
          'sub': 'Chiết khấu 3.5%, Data 4G/5G',
          'icon': CupertinoIcons.antenna_radiowaves_left_right,
          'color': const Color(0xFF0284C7),
          'route': '/data-topup',
        },
        {
          'name': 'Vé Máy Bay Số',
          'sub': 'Vé điện tử IATA, Check-in',
          'icon': CupertinoIcons.airplane,
          'color': const Color(0xFF0D9488),
          'route': '/digital-flight',
        },
        {
          'name': 'Vé máy bay iMedia',
          'sub': 'Giá tốt nhất, bảo hiểm trễ',
          'icon': CupertinoIcons.paperplane_fill,
          'color': const Color(0xFF2563EB),
          'route': '/imedia-flight',
        },
        {
          'name': 'Data 4G / Thẻ Game',
          'sub': 'Garena, Zing, VTC chiết khấu 5%',
          'icon': CupertinoIcons.gamecontroller_fill,
          'color': const Color(0xFF7C3AED),
          'route': '/game-cards',
        },
        {
          'name': 'Vận Số Phong Thủy',
          'sub': 'Hoàng đạo, Giờ tốt, Quẻ tài lộc',
          'icon': CupertinoIcons.sun_max_fill,
          'color': const Color(0xFFB45309),
          'route': '/van-so',
        },
      ],
    },
    {
      'title': 'Tài chính & Thẻ Ngân hàng',
      'items': [
        {
          'name': 'Chuyển tiền Napas 24/7',
          'sub': 'Miễn phí chuyển liên ngân hàng',
          'icon': CupertinoIcons.arrow_right_arrow_left,
          'color': AppColors.primary,
          'route': '/transfer',
        },
        {
          'name': 'Rút tiền ATM không thẻ',
          'sub': 'Mã PIN bảo mật, rút nhanh tại ATM',
          'icon': CupertinoIcons.money_dollar_circle_fill,
          'color': const Color(0xFF059669),
          'route': '/atm-withdrawal',
        },
        {
          'name': 'Mở tài khoản số đẹp',
          'sub': 'Tứ quý, lộc phát, ngũ quý',
          'icon': CupertinoIcons.star_fill,
          'color': const Color(0xFFD97706),
          'route': '/lucky-account',
        },
        {
          'name': 'Chuyển tiền quốc tế',
          'sub': 'Swift Code, tỷ giá ưu đãi',
          'icon': CupertinoIcons.globe,
          'color': const Color(0xFF2563EB),
          'route': '/international-transfer',
        },
        {
          'name': 'Quản lý thẻ ngân hàng',
          'sub': 'Thẻ ghi nợ, thẻ tín dụng Quốc tế',
          'icon': CupertinoIcons.creditcard_fill,
          'color': const Color(0xFF475569),
          'route': '/cards',
        },
        {
          'name': 'Gửi tiết kiệm Phát Lộc',
          'sub': 'Lãi suất tới 7.4%/năm',
          'icon': CupertinoIcons.briefcase_fill,
          'color': const Color(0xFF059669),
          'route': '/savings',
        },
      ],
    },
    {
      'title': 'Hóa đơn & Tiện ích sinh hoạt',
      'items': [
        {
          'name': 'Tiền điện EVN',
          'sub': 'Tự động trích nợ hàng tháng',
          'icon': CupertinoIcons.bolt_fill,
          'color': const Color(0xFFF59E0B),
          'route': '/bills',
        },
        {
          'name': 'Tiền nước sinh hoạt',
          'sub': 'Các công ty cấp nước toàn quốc',
          'icon': CupertinoIcons.drop_fill,
          'color': const Color(0xFF0284C7),
          'route': '/bills',
        },
        {
          'name': 'Bảo hiểm xã hội',
          'sub': 'Đóng VssID, gia hạn BHYT',
          'icon': CupertinoIcons.shield_fill,
          'color': const Color(0xFF0D9488),
          'route': '/social-insurance',
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
          'Tất Cả Dịch Vụ',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Thanh tìm kiếm dịch vụ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _searchKeyword = val.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nhanh dịch vụ, tiện ích...',
                  prefixIcon: const Icon(CupertinoIcons.search,
                      size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(CupertinoIcons.clear_circled_solid,
                              size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchKeyword = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.2),
                  ),
                ),
              ),
            ),
          ),

          // Các danh mục dịch vụ
          ..._sections.map((section) {
            final items =
                (section['items'] as List<Map<String, dynamic>>).where((item) {
              if (_searchKeyword.isEmpty) return true;
              final name = (item['name'] as String).toLowerCase();
              final sub = (item['sub'] as String).toLowerCase();
              return name.contains(_searchKeyword) ||
                  sub.contains(_searchKeyword);
            }).toList();

            if (items.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      section['title'] as String,
                      style: AppTypography.titleSmall(
                              color: const Color(0xFF1E293B))
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push(item['route'] as String);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                      width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: (item['color'] as Color)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(item['icon'] as IconData,
                                          color: item['color'] as Color,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] as String,
                                            style: AppTypography.bodyMedium(
                                                    color:
                                                        const Color(0xFF1E293B))
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w700),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['sub'] as String,
                                            style: AppTypography.bodySmall(
                                                color: const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(CupertinoIcons.chevron_right,
                                        size: 14, color: Color(0xFFCBD5E1)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            );
          }),

          // Đệm 110dp chống cấn Bottom Bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }
}
