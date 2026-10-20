import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  int _selectedWallpaperIdx = 0;
  String _selectedLanguage = 'Tiếng Việt';
  bool _notificationSound = true;
  bool _hapticFeedback = true;
  double _cacheSizeMb = 48.6;
  bool _isClearingCache = false;

  // New Banking Settings
  bool _hideBalanceOnHome = false;
  bool _maskSensitiveDataOnShare = true;
  bool _blockScreenCapture = true;
  bool _receivePromoMessages = true;

  double _transferLimitPerDay = 50000000;
  double _ecomLimitPerDay = 20000000;
  double _atmLimitPerDay = 30000000;

  final List<String> _wallpapers = [
    'Hoa Sen Cung Đình',
    'Đêm Phố Cổ Hà Nội',
    'Sơn Trà Đà Nẵng',
    'Hoàng Hôn Sài Gòn',
  ];

  void _clearCache() {
    setState(() => _isClearingCache = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isClearingCache = false;
        _cacheSizeMb = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Đã dọn dẹp toàn bộ bộ nhớ đệm cache ứng dụng (0 MB)!'),
        ),
      );
    });
  }

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.star_circle_fill,
                color: AppColors.accentGold, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Đánh Giá Trải Nghiệm Sen Hồng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ý kiến đóng góp của quý khách giúp chúng tôi không ngừng hoàn thiện dịch vụ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (idx) {
                return IconButton(
                  icon: const Icon(CupertinoIcons.star_fill,
                      color: AppColors.accentGold, size: 32),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.emeraldGreen,
                        content:
                            Text('Cảm ơn bạn đã đánh giá 5 sao cho Sen Hồng!'),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAliasModal() {
    final aliasCtrl = TextEditingController(text: 'SEN.NGUYENVANA');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.at,
                        color: AppColors.bottomBarCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tài Khoản Biệt Danh (Alias)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill,
                      color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Đặt biệt danh ngắn gọn thay thế số tài khoản ngân hàng để người khác chuyển tiền cho bạn nhanh chóng và phong cách hơn.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aliasCtrl,
              style: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Biệt danh tài khoản (Alias)',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(CupertinoIcons.person_badge_plus_fill,
                    color: AppColors.bottomBarCyan),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.emeraldGreen,
                      content: Text(
                          'Đăng ký Alias "${aliasCtrl.text}" thành công!'),
                    ),
                  );
                },
                child: const Text('Lưu Biệt Danh Alias',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cài Đặt Ứng Dụng'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            // 1. App Version Badge Card
            _buildAppVersionCard(),
            const SizedBox(height: 20),

            // 2. Transaction Limit Management Hub
            _buildSectionHeader('QUẢN LÝ HẠN MỨC GIAO DỊCH'),
            const SizedBox(height: 10),
            _buildTransactionLimitsCard(),
            const SizedBox(height: 22),

            // 3. Privacy & Display Hub
            _buildSectionHeader('QUYỀN RIÊNG TƯ & HIỂN THỊ'),
            const SizedBox(height: 10),
            _buildPrivacySettingsCard(),
            const SizedBox(height: 22),

            // 4. UI & Themes
            _buildSectionHeader('GIAO DIỆN & TRẢI NGHIỆM'),
            const SizedBox(height: 10),
            _buildThemeSettingsCard(),
            const SizedBox(height: 22),

            // 5. Wallpapers Carousel
            _buildSectionHeader('HÌNH NỀN CÁ NHÂN HÓA'),
            const SizedBox(height: 10),
            _buildWallpapersSelector(),
            const SizedBox(height: 22),

            // 6. Security & Device Fast-Links
            _buildSectionHeader('BẢO MẬT & THIẾT BỊ'),
            const SizedBox(height: 10),
            _buildSecurityLinksCard(),
            const SizedBox(height: 22),

            // 7. Cache & Rating
            _buildSectionHeader('BỘ NHỚ & PHẢN HỒI'),
            const SizedBox(height: 10),
            _buildCacheAndRatingCard(),
            const SizedBox(height: 22),

            // 8. Developer & Legal Footer
            _buildSectionHeader('THÔNG TIN PHÁP LÝ & HỆ THỐNG'),
            const SizedBox(height: 10),
            _buildLegalAndDevCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.bottomBarCyan,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAppVersionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF132A48), Color(0xFF0C1929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/splash'),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bottomBarCyan, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset('assets/icons/senbank_logo.png',
                      fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SENBANK DIGITAL BANK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Phiên bản 2.4.0 • Build 20260906 (Ổn định)',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emeraldGreen),
                ),
                child: const Text(
                  'STABLE',
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionLimitsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLimitRow(
              title: 'Hạn mức chuyển khoản / ngày',
              sub: 'Áp dụng cho Chuyển khoản trong & ngoài hệ thống NAPAS',
              val: _transferLimitPerDay,
              onTapEdit: () => _showLimitDialog(
                'Hạn Mức Chuyển Khoản / Ngày',
                _transferLimitPerDay,
                (newVal) => setState(() => _transferLimitPerDay = newVal),
              ),
            ),
            _buildDivider(),
            _buildLimitRow(
              title: 'Hạn mức thanh toán thẻ trực tuyến',
              sub: 'Giao dịch thương mại điện tử e-Commerce (Shopee, Grab, Booking...)',
              val: _ecomLimitPerDay,
              onTapEdit: () => _showLimitDialog(
                'Hạn Mức Thanh Toán Trực Tuyến',
                _ecomLimitPerDay,
                (newVal) => setState(() => _ecomLimitPerDay = newVal),
              ),
            ),
            _buildDivider(),
            _buildLimitRow(
              title: 'Hạn mức rút tiền mặt tại CDM/ATM',
              sub: 'Giới hạn rút tiền mặt bằng mã QR hoặc thẻ vật lý trong 24h',
              val: _atmLimitPerDay,
              onTapEdit: () => _showLimitDialog(
                'Hạn Mức Rút Tiền Mặt / Ngày',
                _atmLimitPerDay,
                (newVal) => setState(() => _atmLimitPerDay = newVal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow({
    required String title,
    required String sub,
    required double val,
    required VoidCallback onTapEdit,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onTapEdit,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.formatVND(val),
                  style: const TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.pencil,
                    color: AppColors.bottomBarCyan, size: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLimitDialog(
      String title, double currentVal, ValueChanged<double> onSaved) {
    double tempVal = currentVal;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A),
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.formatVND(tempVal),
                style: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Slider(
                value: tempVal,
                min: 5000000,
                max: 100000000,
                divisions: 19,
                activeColor: AppColors.bottomBarCyan,
                inactiveColor: Colors.white12,
                onChanged: (v) => setDlgState(() => tempVal = v),
              ),
              const Text(
                'Điều chỉnh hạn mức tức thì. Với hạn mức > 100 triệu, vui lòng xác thực eKYC Cấp 3.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                onSaved(tempVal);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.emeraldGreen,
                    content: Text('Đã cập nhật hạn mức thành công!'),
                  ),
                );
              },
              child: const Text('Lưu Hạn Mức'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettingsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          _buildSwitchRow(
            title: 'Tự động ẩn số dư trên Trang chủ',
            subtitle: 'Bảo vệ số dư khỏi ánh nhìn của người xung quanh ở nơi công cộng',
            val: _hideBalanceOnHome,
            onChanged: (v) => setState(() => _hideBalanceOnHome = v),
          ),
          _buildDivider(),
          _buildSwitchRow(
            title: 'Che bớt số tài khoản khi chia sẻ',
            subtitle: 'Tự động ẩn 4 số giữa của STK khi xuất ảnh biên lai chuyển tiền',
            val: _maskSensitiveDataOnShare,
            onChanged: (v) => setState(() => _maskSensitiveDataOnShare = v),
          ),
          _buildDivider(),
          _buildSwitchRow(
            title: 'Chống chụp màn hình & quay lén',
            subtitle: 'Ngăn chặn ứng dụng độc hại chụp trộm màn hình nhập mã PIN',
            val: _blockScreenCapture,
            onChanged: (v) => setState(() => _blockScreenCapture = v),
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              onTap: _showAliasModal,
              leading: const Icon(CupertinoIcons.at,
                  color: AppColors.bottomBarCyan, size: 22),
              title: const Text(
                'Tài khoản Biệt danh (Alias / Nickname)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              subtitle: const Text(
                'Đang dùng: SEN.NGUYENVANA • Đổi biệt danh',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          _buildSwitchRow(
            title: 'Chế độ Tối (Dark Liquid Theme)',
            subtitle: 'Tối ưu hóa hiển thị thẻ kính mờ trên nền đêm huyền bí',
            val: _isDarkMode,
            onChanged: (v) => setState(() => _isDarkMode = v),
          ),
          _buildDivider(),
          _buildSwitchRow(
            title: 'Âm thanh biến động số dư (Ting Ting)',
            subtitle: 'Phát âm thanh chuông ngân chuẩn ngân hàng khi nhận tiền',
            val: _notificationSound,
            onChanged: (v) => setState(() => _notificationSound = v),
          ),
          _buildDivider(),
          _buildSwitchRow(
            title: 'Rung phản hồi xúc giác (Haptic Touch)',
            subtitle: 'Rung nhẹ tinh tế khi bấm bàn phím số PIN và quét vân tay',
            val: _hapticFeedback,
            onChanged: (v) => setState(() => _hapticFeedback = v),
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: const Icon(CupertinoIcons.globe,
                  color: AppColors.bottomBarCyan, size: 22),
              title: const Text(
                'Ngôn ngữ ứng dụng (Language)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF0D1B2A),
                underline: const SizedBox(),
                style: const TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.bold),
                items: ['Tiếng Việt', 'English', '日本語']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpapersSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_wallpapers.length, (idx) {
          final wp = _wallpapers[idx];
          final isSelected = _selectedWallpaperIdx == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedWallpaperIdx = idx),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.bottomBarCyan.withValues(alpha: 0.15)
                      : const Color(0xFF0C1929).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.bottomBarCyan
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: idx == 0
                              ? [AppColors.primaryDark, AppColors.bottomBarCyan]
                              : (idx == 1
                                  ? [AppColors.primaryDark, const Color(0xFF132A48)]
                                  : [
                                      AppColors.emeraldGreen,
                                      AppColors.primaryDark
                                    ]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: isSelected
                          ? const Icon(CupertinoIcons.checkmark_circle_fill,
                              color: Colors.white, size: 26)
                          : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.bottomBarCyan
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSecurityLinksCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          _buildNavTile(
            icon: CupertinoIcons.shield_lefthalf_fill,
            iconColor: AppColors.primary,
            title: 'Cài đặt bảo mật & Smart OTP',
            subtitle: 'Đổi mật khẩu, PIN 6 số, sinh trắc học QĐ 2345',
            onTap: () => context.push('/settings/security'),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: CupertinoIcons.device_phone_portrait,
            iconColor: AppColors.bottomBarCyan,
            title: 'Quản lý thiết bị & Phiên đăng nhập',
            subtitle: 'Kiểm soát các máy đang truy cập, khóa từ xa',
            onTap: () => context.push('/settings/devices'),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: CupertinoIcons.bell_fill,
            iconColor: AppColors.accentGold,
            title: 'Cài đặt thông báo biến động số dư',
            subtitle: 'Tùy chỉnh thông báo OTT, biến động nạp rút',
            onTap: () => context.push('/notifications/settings'),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: CupertinoIcons.doc_plaintext,
            iconColor: AppColors.emeraldGreen,
            title: 'Điều khoản dịch vụ & Bảo vệ dữ liệu',
            subtitle: 'Chính sách bảo mật theo Nghị định 13/2023/NĐ-CP',
            onTap: () => context.push('/auth/terms'),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheAndRatingCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: const Icon(CupertinoIcons.trash_circle_fill,
                  color: AppColors.accentGold, size: 24),
              title: const Text(
                'Dọn dẹp bộ nhớ đệm (Cache)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              subtitle: Text(
                'Dung lượng tạm thời: ${_cacheSizeMb.toStringAsFixed(1)} MB',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: _isClearingCache
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bottomBarCyan,
                        side: BorderSide(
                            color:
                                AppColors.bottomBarCyan.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      onPressed: _cacheSizeMb > 0 ? _clearCache : null,
                      child: Text(
                          _cacheSizeMb > 0 ? 'Xóa cache' : 'Đã sạch',
                          style: const TextStyle(fontSize: 11)),
                    ),
            ),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: CupertinoIcons.star_fill,
            iconColor: AppColors.accentGold,
            title: 'Đánh giá ứng dụng SenBank',
            subtitle: 'Gửi nhận xét trải nghiệm trên chợ ứng dụng App Store / Google Play',
            onTap: _showRatingModal,
          ),
          _buildDivider(),
          _buildSwitchRow(
            title: 'Nhận bản tin ưu đãi & hoàn tiền',
            subtitle: 'Nhận thông báo mã giảm giá tiền điện nước và lãi suất tiết kiệm',
            val: _receivePromoMessages,
            onChanged: (v) => setState(() => _receivePromoMessages = v),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalAndDevCard() {
    return Column(
      children: [
        GlassCard(
          quality: GlassQuality.minimal,
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              onTap: () => context.push('/settings/config'),
              leading: const Icon(CupertinoIcons.gear_alt_fill,
                  color: AppColors.bottomBarCyan, size: 22),
              title: const Text(
                'Cấu hình Mạng & API Core Banking',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              subtitle: const Text(
                'Đổi Gateway, kiểm tra Ping RTT, nhật ký gói tin Live',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.building_2_fill,
                      color: AppColors.bottomBarCyan, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'NGÂN HÀNG SỐ SEN HỒNG (SENBANK VIỆT NAM)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                '• Giấy phép thành lập và hoạt động số: 128/GP-NHNN do Thống đốc Ngân hàng Nhà nước cấp.\n• Hội sở chính: Tòa nhà Sen Hồng Tower, 54 Liễu Giai, P. Cống Vị, Q. Ba Đình, Hà Nội.\n• Tổng đài chăm sóc khách hàng VIP 24/7: 1900 6688\n• Email hỗ trợ kỹ thuật: support@senbank.vn',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: val,
            activeTrackColor: AppColors.bottomBarCyan,
            onChanged: (newVal) {
              HapticFeedback.selectionClick();
              onChanged(newVal);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: const Icon(CupertinoIcons.chevron_forward,
            color: Colors.white38, size: 16),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
