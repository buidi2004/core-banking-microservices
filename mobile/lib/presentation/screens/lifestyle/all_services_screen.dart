import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';

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
          'icon': LucideIcons.sparkles,
          'route': '/vua-xo-so',
        },
        {
          'name': 'Vé số Vietlott',
          'sub': 'Power 6/55, Mega 6/45, Keno',
          'icon': LucideIcons.ticket,
          'route': '/vietlott',
        },
        {
          'name': 'Data 4G / Nạp tiền',
          'sub': 'Chiết khấu 3.5%, Data 4G/5G',
          'icon': LucideIcons.smartphone,
          'route': '/data-topup',
        },
        {
          'name': 'Vé Máy Bay Số',
          'sub': 'Vé điện tử IATA, Check-in',
          'icon': LucideIcons.plane,
          'route': '/digital-flight',
        },
        {
          'name': 'Vé máy bay iMedia',
          'sub': 'Giá tốt nhất, bảo hiểm trễ',
          'icon': LucideIcons.send,
          'route': '/imedia-flight',
        },
        {
          'name': 'Data 4G / Thẻ Game',
          'sub': 'Garena, Zing, VTC chiết khấu 5%',
          'icon': LucideIcons.gamepad2,
          'route': '/game-cards',
        },
        {
          'name': 'Vận Số Phong Thủy',
          'sub': 'Hoàng đạo, Giờ tốt, Quẻ tài lộc',
          'icon': LucideIcons.sun,
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
          'icon': LucideIcons.arrowLeftRight,
          'route': '/transfer',
        },
        {
          'name': 'Rút tiền ATM không thẻ',
          'sub': 'Mã PIN bảo mật, rút nhanh tại ATM',
          'icon': LucideIcons.banknote,
          'route': '/atm-withdrawal',
        },
        {
          'name': 'Mở tài khoản số đẹp',
          'sub': 'Tứ quý, lộc phát, ngũ quý',
          'icon': LucideIcons.star,
          'route': '/lucky-account',
        },
        {
          'name': 'Chuyển tiền quốc tế',
          'sub': 'Swift Code, tỷ giá ưu đãi',
          'icon': LucideIcons.globe,
          'route': '/international-transfer',
        },
        {
          'name': 'Quản lý thẻ ngân hàng',
          'sub': 'Thẻ ghi nợ, thẻ tín dụng Quốc tế',
          'icon': LucideIcons.creditCard,
          'route': '/cards',
        },
        {
          'name': 'Gửi tiết kiệm Phát Lộc',
          'sub': 'Lãi suất tới 7.4%/năm',
          'icon': LucideIcons.landmark,
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
          'icon': LucideIcons.zap,
          'route': '/bills',
        },
        {
          'name': 'Tiền nước sinh hoạt',
          'sub': 'Các công ty cấp nước toàn quốc',
          'icon': LucideIcons.droplets,
          'route': '/bills',
        },
        {
          'name': 'Bảo hiểm xã hội',
          'sub': 'Đóng VssID, gia hạn BHYT',
          'icon': LucideIcons.shieldCheck,
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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'Tất Cả Dịch Vụ',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Thanh tìm kiếm dịch vụ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _searchKeyword = val.toLowerCase().trim()),
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nhanh dịch vụ, tiện ích...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 19,
                    color: Color(0xFF64748B),
                  ),
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.circleX,
                            size: 17,
                            color: Color(0xFF94A3B8),
                          ),
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
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.07),
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.07),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Các danh mục dịch vụ theo phong cách Tối Giản (Minimalist Grouped List)
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
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
                    child: Text(
                      section['title'] as String,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push(item['route'] as String);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  // Icon nét đơn tối giản (không ô màu bao bọc)
                                  Icon(
                                    item['icon'] as IconData,
                                    size: 22,
                                    color: const Color(0xFF616161),
                                  ),
                                  const SizedBox(width: 16),
                                  // Khối nội dung Tiêu đề & Chú thích
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                            letterSpacing: -0.2,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item['sub'] as String,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF6B7280),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Mũi tên dẫn hướng mảnh
                                  const Icon(
                                    LucideIcons.chevronRight,
                                    size: 16,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ],
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

          // Đệm 110dp chống cấn Bottom Bar chuẩn Apple HIG
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }
}
