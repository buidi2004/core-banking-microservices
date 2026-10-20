import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import '../../widgets/user_avatar_widget.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _displayName = 'KHÁCH HÀNG SENBANK';
  String _accountNumber = '';
  String _kycStatus = 'Hội Viên Sen V-Gold • eKYC Cấp 2';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      const storage = FlutterSecureStorage();
      final savedPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      final savedName = await storage.read(key: AppConstants.keyFullName);
      if (mounted && (savedPhone != null || savedName != null)) {
        setState(() {
          if (savedPhone != null && savedPhone.isNotEmpty) _accountNumber = savedPhone;
          if (savedName != null && savedName.isNotEmpty) _displayName = savedName.toUpperCase();
        });
      }

      final profile = await ProfileRemoteDataSource().getMe();
      if (!mounted) return;
      setState(() {
        final fullName = profile['fullName'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          _displayName = fullName.toUpperCase();
        }
        final phone = profile['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          _accountNumber = phone;
        }
      });

      final kyc = await ProfileRemoteDataSource().getKycStatus();
      if (kyc != null && mounted) {
        final status = kyc['status'] as String? ?? 'VERIFIED';
        final level = kyc['level'] ?? 2;
        setState(() {
          _kycStatus = 'Hội Viên Sen V-Gold • eKYC Cấp $level ($status)';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Menu Tiện Ích & Dịch Vụ'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: AppColors.textPrimaryLight),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.bell_fill, color: AppColors.textPrimaryLight),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: Column(
            children: [
              // Enhanced User Card with Real STK & Clipboard
              _buildUserCard(context),
              const SizedBox(height: 16),

              // SenPoints & Loyalty Rewards Banner
              _buildLoyaltyBanner(context),
              const SizedBox(height: 20),

              // Group 1: Tài chính, Thẻ & Tiết kiệm
              _buildMenuSection(
                title: 'Tài chính, Thẻ & Tiết kiệm',
                items: [
                  {'icon': CupertinoIcons.creditcard_fill, 'title': 'Quản lý thẻ Sen Hồng (Visa / Napas)', 'sub': 'Khóa/mở thẻ, hạn mức, PIN thẻ', 'onTap': () => context.push('/cards')},
                  {'icon': CupertinoIcons.archivebox_fill, 'title': 'Tiết kiệm Sen Lộc Phát Online', 'sub': 'Lãi suất dẫn đầu tới 7.4%/năm', 'onTap': () => context.push('/bills/savings')},
                  {'icon': CupertinoIcons.chart_bar_fill, 'title': 'Hạn mức giao dịch & KYC Level', 'sub': '100tr/ngày • Nâng cấp Cấp 3', 'onTap': () => context.push('/profile/kyc-level')},
                  {'icon': CupertinoIcons.person_crop_rectangle_fill, 'title': 'Hồ sơ CCCD & Sinh trắc học', 'sub': 'Đối soát chip C06 QĐ 2345', 'onTap': () => context.push('/profile/identity-document')},
                  {'icon': CupertinoIcons.bolt_horizontal_circle_fill, 'title': 'Vay tiêu dùng siêu tốc', 'sub': 'Hạn mức duyệt sẵn đến 50 triệu', 'onTap': () => context.push('/bills/quick-loan')},
                  {'icon': CupertinoIcons.building_2_fill, 'title': 'Tài khoản ngân hàng liên kết', 'sub': 'Nạp rút nhanh 24/7 miễn phí', 'onTap': () => context.push('/bank-cards')},
                  {'icon': CupertinoIcons.person_2_fill, 'title': 'Danh bạ người thụ hưởng', 'sub': 'Quản lý tài khoản đã lưu', 'onTap': () => context.push('/beneficiaries')},
                ],
              ),
              const SizedBox(height: 16),

              // Group 2: Dịch vụ & Đời sống
              _buildMenuSection(
                title: 'Dịch vụ & Tiện ích Đời sống',
                items: [
                  {'icon': CupertinoIcons.tickets_fill, 'title': 'Vé số Vietlott Online', 'sub': 'Mega 6/45, Power 6/55, Keno', 'onTap': () => context.push('/bills/lottery')},
                  {'icon': CupertinoIcons.device_phone_portrait, 'title': 'Nạp tiền điện thoại (Top-up)', 'sub': 'Chiết khấu 3% Viettel, Vina, Mobi', 'onTap': () => context.push('/bills/phone-recharge')},
                  {'icon': CupertinoIcons.doc_text_fill, 'title': 'Thanh toán hóa đơn thiết yếu', 'sub': 'Điện EVN, Nước, Internet, Truyền hình', 'onTap': () => context.push('/bills')},
                  {'icon': CupertinoIcons.gift_fill, 'title': 'Giới thiệu bạn bè nhận thưởng', 'sub': 'Nhận 50.000đ khi mời bạn mới', 'onTap': () => context.push('/referral')},
                ],
              ),
              const SizedBox(height: 16),

              // Group 3: Bảo mật & Ứng dụng
              _buildMenuSection(
                title: 'Bảo mật & Cấu hình Ứng dụng',
                items: [
                  {'icon': CupertinoIcons.shield_fill, 'title': 'Cài đặt bảo mật & Smart OTP', 'sub': 'FaceID, PIN 6 số, Chữ ký số PKI', 'onTap': () => context.push('/settings/security')},
                  {'icon': CupertinoIcons.lock_shield_fill, 'title': 'Đổi mã PIN giao dịch bảo mật', 'sub': 'Cập nhật mã PIN 6 số với Numpad bảo mật', 'onTap': () => context.push('/settings/change-pin')},
                  {'icon': CupertinoIcons.radiowaves_right, 'title': 'Xác thực Chip CCCD (NFC)', 'sub': 'Quét chip đối soát C06 QĐ 2345', 'onTap': () => context.push('/profile/nfc-reader')},
                  {'icon': CupertinoIcons.bell_fill, 'title': 'Cài đặt thông báo & Chuông Ting Ting', 'sub': 'Quản lý OTT, SMS biến động số dư', 'onTap': () => context.push('/notifications/settings')},
                  {'icon': CupertinoIcons.device_phone_portrait, 'title': 'Quản lý phiên & Thiết bị đăng nhập', 'sub': 'Bảo vệ tài khoản đa thiết bị', 'onTap': () => context.push('/settings/devices')},
                  {'icon': CupertinoIcons.paintbrush_fill, 'title': 'Giao diện Liquid Glass & Hình nền', 'sub': 'Tùy biến màu sắc và độ mờ kính', 'onTap': () => context.push('/settings')},
                  {'icon': CupertinoIcons.sparkles, 'title': 'Hiệu ứng mở app Hoa Sen Nở', 'sub': 'Trải nghiệm lại màn hình chào hoa sen nở 3D', 'onTap': () => context.push('/splash')},
                  {'icon': CupertinoIcons.antenna_radiowaves_left_right, 'title': 'Cấu hình Server API & Gateway', 'sub': 'Tùy chỉnh máy chủ kết nối backend', 'onTap': () => context.push('/settings/config')},
                ],
              ),
              const SizedBox(height: 16),

              // Group 4: Chăm sóc khách hàng & Pháp lý
              _buildMenuSection(
                title: 'Trợ giúp & Pháp lý Ngân hàng',
                items: [
                  {'icon': CupertinoIcons.phone_circle_fill, 'title': 'Trung tâm trợ giúp & Hotline 24/7', 'sub': '1900 6688 • Khóa thẻ khẩn cấp', 'onTap': () => context.push('/support/help-center')},
                  {'icon': CupertinoIcons.question_diamond_fill, 'title': 'Live Chat với chuyên viên tư vấn', 'sub': 'Phản hồi trong 30 giây', 'onTap': () => context.push('/support/live-chat')},
                  {'icon': CupertinoIcons.doc_text_fill, 'title': 'Điều khoản dịch vụ & Giấy phép NHNN', 'sub': 'Quy định pháp lý và bảo vệ dữ liệu', 'onTap': () => context.push('/auth/terms')},
                ],
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(
                          children: [
                            Icon(CupertinoIcons.square_arrow_right_fill, color: AppColors.error),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Đăng Xuất Tài Khoản?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimaryLight)),
                            ),
                          ],
                        ),
                        content: const Text(
                          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Sen Hồng Bank trên thiết bị này?',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy', style: TextStyle(color: AppColors.textMutedLight)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(ctx);
                              const storage = FlutterSecureStorage();
                              await storage.delete(key: AppConstants.keyAccessToken);
                              await storage.delete(key: AppConstants.keyRefreshToken);
                              await storage.delete(key: AppConstants.keyPinToken);
                              await storage.delete(key: AppConstants.keyWalletId);
                              if (context.mounted) {
                                context.go('/auth/login');
                              }
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.square_arrow_right_fill, color: AppColors.error, size: 20),
                  label: Text(
                    'Đăng xuất tài khoản',
                    style: AppTypography.titleSmall(color: AppColors.error).copyWith(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.85),
                    side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Banking Footer & License
              _buildBankingFooter(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildUserCard(BuildContext context) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/profile');
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatarWidget(
                radius: 28,
                borderColor: AppColors.primaryLight,
                onTap: () => context.push('/profile'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('STK: $_accountNumber', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _accountNumber));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emeraldGreen,
                                content: Text('Đã sao chép STK: $_accountNumber vào bộ nhớ tạm'),
                              ),
                            );
                          },
                          child: const Icon(CupertinoIcons.doc_on_doc, size: 14, color: AppColors.bottomBarCyan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _kycStatus,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.cardDark, AppColors.textPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.star_circle_fill, color: AppColors.accentGold, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12.450 SenPoints',
                  style: TextStyle(color: AppColors.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Đổi voucher Grab, Shopee, Highlands Coffee',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentGold),
              foregroundColor: AppColors.accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/promotions');
            },
            child: const Text('Đổi quà', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Map<String, dynamic>> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        GlassCard(
          quality: GlassQuality.minimal,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == items.length - 1;
              return Column(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        (item['onTap'] as VoidCallback)();
                      },
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      subtitle: item['sub'] != null
                          ? Text(
                              item['sub'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            )
                          : null,
                      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 64, color: AppColors.dividerLight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBankingFooter() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.suit_diamond_fill, size: 14, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'SEN HỒNG DIGITAL BANK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimaryLight, letterSpacing: 0.8),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Giấy phép hoạt động số 88/GP-NHNN do Ngân hàng Nhà nước cấp\n'
          'Bảo hiểm tiền gửi Việt Nam (DIV) bảo trợ theo Luật các TCTD\n'
          'Hotline 24/7: 1900 6688 • contact@senbank.vn\n'
          'Phiên bản 2.4.0 (Build 2026.09.05)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, height: 1.4),
        ),
      ],
    );
  }
}
