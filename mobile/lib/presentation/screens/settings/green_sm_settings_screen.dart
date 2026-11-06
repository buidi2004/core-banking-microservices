import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons_200.dart';

/// Font bundle cục bộ (đăng ký trong pubspec.yaml) — offline 100%, không FOUT
const String _kFontFamily = 'Be Vietnam Pro';

/// Item điều hướng cho thanh Bottom Bar
class GreenSmNavItem {
  final IconData icon;
  final String label;

  const GreenSmNavItem({required this.icon, required this.label});
}

// ============================================================================
// LAYOUT TOKENS — hằng số dùng chung, đảm bảo nhất quán trên mọi kích thước
// màn hình (điện thoại nhỏ → tablet → landscape) thay vì số "magic" rải rác.
// ============================================================================
const double _kBarItemHeight = 66.0; // chiều cao thanh Bottom Bar
const double _kBarFallbackMargin =
    16.0; // lề đáy khi thiết bị không có safe inset
const double _kBarContentGap = 22.0; // khoảng hở giữa item cuối và thanh Bar
const double _kMaxContentWidth =
    640.0; // giới hạn bề ngang danh sách (tablet/web)
const double _kMaxBarWidth = 520.0; // giới hạn bề ngang thanh Bar (tablet/web)
const double _kMaxTextScale =
    1.35; // chặn phóng chữ hệ thống quá lớn làm vỡ layout

/// Dữ liệu 1 dòng cài đặt — immutable & const, rebuild rẻ, dễ duy trì
class _GreenSmItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool hasToggle; // dòng chứa CupertinoSwitch thay vì chevron

  const _GreenSmItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.hasToggle = false,
  });
}

/// Nhóm cài đặt (header tuỳ chọn + danh sách item)
class _GreenSmSection {
  final String? header;
  final List<_GreenSmItem> items;

  const _GreenSmSection({this.header, required this.items});
}

/// Màn hình Cài đặt chuẩn Xanh SM / Green SM kết hợp Floating Glass Bottom Bar.
///
/// Tối ưu "chuẩn mọi màn hình":
/// - Giới hạn bề ngang nội dung [_kMaxContentWidth] và thanh Bar [_kMaxBarWidth],
///   căn giữa trên tablet/landscape — không giãn méo trên màn lớn.
/// - Padding đáy tính động từ safe inset + chiều cao Bar (không hardcode 120dp).
/// - Chặn hệ số phóng chữ hệ thống ở [_kMaxTextScale] (vẫn thân thiện người cao
///   tuổi ~35% lớn hơn) để không bao giờ tràn/chèn chữ trên màn hẹp.
class GreenSmSettingsScreen extends StatefulWidget {
  const GreenSmSettingsScreen({super.key});

  @override
  State<GreenSmSettingsScreen> createState() => _GreenSmSettingsScreenState();
}

class _GreenSmSettingsScreenState extends State<GreenSmSettingsScreen> {
  bool _isSimpleModeEnabled = false;
  int _selectedTabIndex = 4; // Mặc định ở tab "Tài khoản"

  static const List<GreenSmNavItem> _navTabs = [
    GreenSmNavItem(icon: LucideIcons200.car, label: 'Đặt xe'),
    GreenSmNavItem(icon: LucideIcons200.bike, label: 'Giao hàng'),
    GreenSmNavItem(icon: LucideIcons200.clock, label: 'Hoạt động'),
    GreenSmNavItem(icon: LucideIcons200.messageSquare, label: 'Tin nhắn'),
    GreenSmNavItem(icon: LucideIcons200.user, label: 'Tài khoản'),
  ];

  // Dữ liệu menu khai báo dạng const — tách dữ liệu khỏi UI, tiện thêm/bớt mục
  static const List<_GreenSmSection> _sections = [
    _GreenSmSection(
      items: [
        _GreenSmItem(
            icon: LucideIcons200.contact, title: 'Trở thành tài xế Green SM'),
        _GreenSmItem(icon: LucideIcons200.map, title: 'Đóng góp bản đồ'),
        _GreenSmItem(
            icon: LucideIcons200.info, title: 'Điều khoản & Chính sách'),
        _GreenSmItem(
            icon: LucideIcons200.building2, title: 'Thông tin công ty'),
        _GreenSmItem(
            icon: LucideIcons200.fileCheck2, title: 'Hợp đồng sử dụng dịch vụ'),
        _GreenSmItem(
            icon: LucideIcons200.fileEdit, title: 'Kiểm soát quyền riêng tư'),
      ],
    ),
    _GreenSmSection(
      header: 'Cài đặt chung',
      items: [
        _GreenSmItem(
            icon: Icons.public, title: 'Quốc gia', trailingText: 'Việt Nam'),
        _GreenSmItem(
            icon: LucideIcons200.languages,
            title: 'Ngôn ngữ',
            trailingText: 'Tiếng Việt'),
        _GreenSmItem(
          icon: LucideIcons200.slidersHorizontal,
          title: 'Bật chế độ tối giản',
          subtitle: 'Được tối ưu hóa cho người cao tuổi và trẻ em',
          hasToggle: true,
        ),
        _GreenSmItem(
            icon: LucideIcons200.shieldCheck, title: 'Đăng nhập và bảo mật'),
        _GreenSmItem(icon: LucideIcons200.heart, title: 'Địa chỉ đã lưu'),
        _GreenSmItem(icon: LucideIcons200.receipt, title: 'Hóa đơn'),
        _GreenSmItem(icon: LucideIcons200.star, title: 'Đánh giá Ứng dụng'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Áp dụng font Be Vietnam Pro bundle (geometric sans-serif rõ nét tiếng
    // Việt) — dùng apply() thay google_fonts để khỏi tải font qua mạng lúc chạy
    final textTheme = Theme.of(context).textTheme.apply(
          fontFamily: _kFontFamily,
        );

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      // Chặn phóng chữ hệ thống >1.35x: tránh tràn layout trên màn hẹp mà vẫn
      // hỗ trợ cỡ chữ lớn cho người mắt kém (chế độ tối giản của app)
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _kMaxTextScale,
        child: Scaffold(
          backgroundColor:
              const Color(0xFFFBFBF9), // Màu trắng ngà nhẹ chuẩn ảnh gốc
          extendBody: true, // Cho phép nội dung trượt ra sau kính mờ
          body: SafeArea(
            bottom: false, // Danh sách tràn xuống tận mép đáy, tự tính padding
            child: Builder(
              builder: (context) {
                // Padding đáy động = chiều cao Bar + lề đáy thật của thiết bị
                // + khoảng hở thoáng — thay cho con số cố định 120dp cũ
                final bottomInset = MediaQuery.paddingOf(context).bottom;
                final barReserved = _kBarItemHeight +
                    (bottomInset > 0 ? bottomInset : _kBarFallbackMargin) +
                    _kBarContentGap;

                return Center(
                  // Trên tablet/landscape: nội dung không giãn full bề ngang
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 10, 0, barReserved),
                      children: [
                        for (final section in _sections) ...[
                          if (section.header != null)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Text(
                                section.header!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          for (var i = 0; i < section.items.length; i++) ...[
                            _buildMenuItem(section.items[i]),
                            if (i < section.items.length - 1)
                              _buildHairlineDivider(),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Thanh Floating Glass Bottom Bar — tự giới hạn bề ngang & neo đáy
          // an toàn (không dùng Center ở slot này vì nó sẽ chiếm trọn chiều cao
          // còn lại của Scaffold, khiến bar bị đẩy lệch giữa màn hình)
          bottomNavigationBar: RepaintBoundary(
            child: GreenSmGlassBottomBar(
              items: _navTabs,
              currentIndex: _selectedTabIndex,
              onTap: (index) {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = index);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Đường phân cách siêu mỏng hairline 0.5dp thụt lề 56dp (thẳng cột chữ)
  Widget _buildHairlineDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 56, right: 18),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xFFEDEDEA)),
    );
  }

  // Dòng menu chuẩn công thái học Fitts's Law, cao ≥52dp mọi hệ số chữ
  Widget _buildMenuItem(_GreenSmItem item) {
    final isToggleRow = item.hasToggle;

    return Semantics(
      button: !isToggleRow, // Hàng switch tự công bố vai trò toggle
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: const Color(0xFF00B14F).withValues(alpha: 0.04),
          highlightColor: const Color(0xFF00B14F).withValues(alpha: 0.02),
          onTap: isToggleRow
              ? null
              : () {
                  HapticFeedback.selectionClick();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color:
                      const Color(0xFF6B6E70), // Xám chì ánh xanh nhẹ chuẩn ảnh
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                          letterSpacing: -0.1,
                          height: 1.25, // xuống dòng vẫn thoáng trên màn hẹp
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color:
                                Color(0xFF63666A), // Tương phản đạt chuẩn WCAG
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.trailingText != null) ...[
                  // Flexible chống tràn khi chữ phóng lớn trên màn hẹp
                  Flexible(
                    child: Text(
                      item.trailingText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (isToggleRow)
                  CupertinoSwitch(
                    value: _isSimpleModeEnabled,
                    activeTrackColor:
                        const Color(0xFF00B14F), // Xanh lục bảo Xanh SM
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _isSimpleModeEnabled = val);
                    },
                  )
                else
                  const Icon(
                    LucideIcons200.chevronRight,
                    size: 18,
                    color: Color(0xFF8E8E93),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// THANH FLOATING GLASS BOTTOM BAR (TỐI ƯU QUANG HỌC & PERFORMANCE)
// ============================================================================
class GreenSmGlassBottomBar extends StatelessWidget {
  final List<GreenSmNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GreenSmGlassBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final double safeBottomMargin = bottomInset > 0 ? bottomInset : 16.0;

    // Align(heightFactor: 1.0) — shrink-wrap đúng chiều cao bar để Scaffold neo
    // thanh ở đáy màn hình (không nuốt hết chiều cao còn lại); ConstrainedBox
    // giữ bar không giãn quá [_kMaxBarWidth] trên tablet/màn lớn, Align căn giữa
    return Align(
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxBarWidth),
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 0, 16, safeBottomMargin),
          height: _kBarItemHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ------------------------------------------------------------------
              // LAYER 1: NỀN KÍNH MỜ QUANG HỌC (CHỈ FILTER, KHÔNG CHỨA CONTENT)
              // ------------------------------------------------------------------
              ClipRRect(
                borderRadius: BorderRadius.circular(33),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      // Nền trắng mờ 85% giữ độ tương phản chuẩn WCAG AA
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(33),
                      // Viền vát quang học siêu mỏng 0.8dp
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------------------------
              // LAYER 2: VIÊN THUỐC KÍNH TRƯỢT THEO TAB ĐANG CHỌN (SLIDING PILL)
              // ------------------------------------------------------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / items.length;
                  final alignX =
                      -1.0 + (2.0 * currentIndex / (items.length - 1));

                  return AnimatedAlign(
                    alignment: Alignment(alignX, 0),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.fastEaseInToSlowEaseOut,
                    child: Container(
                      width: tabWidth - 8,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B14F).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color:
                              const Color(0xFF00B14F).withValues(alpha: 0.18),
                          width: 0.6,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ------------------------------------------------------------------
              // LAYER 3: NỘI DUNG ICON & CHỮ (SẮC NÉT 100%, KHÔNG BỊ BLUR)
              // ------------------------------------------------------------------
              Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  const activeColor = Color(0xFF00B14F); // Xanh lục bảo Xanh SM
                  const inactiveColor = Color(0xFF8E8E93);

                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      label: item.label,
                      child: GestureDetector(
                        behavior:
                            HitTestBehavior.opaque, // Vùng chạm = toàn ô tab
                        onTap: () => onTap(index),
                        child: Center(
                          child: AnimatedScale(
                            scale: isSelected ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 21,
                                  color:
                                      isSelected ? activeColor : inactiveColor,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? activeColor
                                        : inactiveColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
