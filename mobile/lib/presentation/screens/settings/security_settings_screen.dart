import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricLogin = true;
  final bool _faceMatchQd2345 = true;
  bool _twoFactorAuth = true;
  bool _pinLockApp = false;
  bool _geoFencingProtection = true;
  int _selectedBioThresholdIdx = 1; // 0: 5tr, 1: 10tr (QĐ 2345), 2: Mọi GD

  final List<String> _thresholdLabels = [
    'Từ 5.000.000 đ',
    'Từ 10.000.000 đ (Chuẩn QĐ 2345)',
    'Mọi giao dịch bất kể số tiền',
  ];

  void _showChangePasswordModal() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Đổi Mật Khẩu Đăng Nhập',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(CupertinoIcons.lock_fill,
                      color: AppColors.bottomBarCyan),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(CupertinoIcons.lock_fill,
                      color: AppColors.bottomBarCyan),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(CupertinoIcons.checkmark_shield_fill,
                      color: AppColors.bottomBarCyan),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                    if (newPassCtrl.text != confirmPassCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text('Mật khẩu mới xác nhận không khớp'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.emeraldGreen,
                        content: Text('Đổi mật khẩu thành công!'),
                      ),
                    );
                  },
                  child: const Text('Lưu Mật Khẩu Mới',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyLockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Row(
          children: [
            Icon(CupertinoIcons.shield_slash_fill,
                color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text('Khóa Khẩn Cấp Tài Khoản?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text(
          'Tất cả giao dịch trực tuyến, thẻ và phiên đăng nhập trên các thiết bị sẽ bị tạm khóa ngay lập tức trong 30 giây để bảo vệ số dư của bạn. Bạn sẽ cần xác thực Face Match eKYC hoặc ra quầy giao dịch để mở khóa lại.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Hủy bỏ', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.error,
                  content: Text(
                      'Tài khoản đã được KHÓA KHẨN CẤP thành công. Vui lòng liên hệ Hotline 1900 6688 khi cần mở lại.'),
                ),
              );
            },
            child: const Text('Xác nhận Khóa Ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cài Đặt Bảo Mật & An Ninh'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            // 1. Security Health Score Card (95/100)
            _buildSecurityScoreCard(),
            const SizedBox(height: 20),

            // 2. Smart OTP PKI Hub Card
            _buildSmartOtpHubCard(),
            const SizedBox(height: 22),

            // 3. QĐ 2345/QĐ-NHNN & Biometrics Section
            _buildSectionHeader('SINH TRẮC HỌC & QUYẾT ĐỊNH 2345/QĐ-NHNN'),
            const SizedBox(height: 10),
            _buildBiometricsCard(),
            const SizedBox(height: 22),

            // 4. Biometric Threshold Selector
            _buildSectionHeader('NGƯỠNG XÁC THỰC KHUÔN MẶT FACEMATCH'),
            const SizedBox(height: 10),
            _buildThresholdSelectorCard(),
            const SizedBox(height: 22),

            // 5. Geo-Fencing Protection
            _buildSectionHeader('BẢO VỆ ĐỊA LÝ & CHỐNG HACKER NƯỚC NGOÀI'),
            const SizedBox(height: 10),
            _buildGeoFencingCard(),
            const SizedBox(height: 22),

            // 6. Access Control & 2FA
            _buildSectionHeader('KIỂM SOÁT ỨNG DỤNG & PHIÊN ĐĂNG NHẬP'),
            const SizedBox(height: 10),
            _buildAccessControlCard(),
            const SizedBox(height: 22),

            // 7. Passwords & PINs
            _buildSectionHeader('MẬT KHẨU & MÃ PIN GIAO DỊCH'),
            const SizedBox(height: 10),
            _buildCredentialsCard(),
            const SizedBox(height: 22),

            // 8. 30-Day Malware & Security Audit Log
            _buildSectionHeader('NHẬT KÝ KIỂM TRA MÃ ĐỘC 30 NGÀY'),
            const SizedBox(height: 10),
            _buildSecurityAuditLogCard(),
            const SizedBox(height: 24),

            // 9. Emergency Lock Button
            _buildEmergencyLockButton(),
            const SizedBox(height: 20),
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

  Widget _buildSecurityScoreCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B48), Color(0xFF0C1929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGreen.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.emeraldGreen, width: 2.5),
            ),
            child: const Center(
              child: Text(
                '95',
                style: TextStyle(
                  color: AppColors.emeraldGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ĐIỂM AN TOÀN: XUẤT SẮC',
                      style: TextStyle(
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(CupertinoIcons.checkmark_seal_fill,
                        color: AppColors.emeraldGreen, size: 14),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'Tài khoản được bảo vệ bởi 4 lớp an ninh: Chip CCCD eKYC C06, Smart OTP PKI, FaceMatch 3D và Mã hóa phần cứng Keystore.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartOtpHubCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF132A48), Color(0xFF0C1929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bottomBarCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.device_phone_portrait,
                        color: AppColors.bottomBarCyan, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMART OTP SEN HỒNG (PKI)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Thiết bị chính: Apple iPhone 15 Pro Max',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'ĐANG HOẠT ĐỘNG',
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Khóa ký số bảo mật: 8F7D-42A1-998C-EE10\nChu kỳ sinh mã xác thực: 30 giây tự động, không phụ thuộc sóng di động SMS.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => context.push('/set-pin'),
                  child: const Text('Đổi PIN Smart OTP',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bottomBarCyan,
                    foregroundColor: const Color(0xFF030B17),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.emeraldGreen,
                        content: Text(
                            'Mã kích hoạt dự phòng đã được gửi vào Email chính chủ.'),
                      ),
                    );
                  },
                  child: const Text('Lấy mã kích hoạt',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _faceMatchQd2345,
            activeTrackColor: AppColors.bottomBarCyan,
            title: const Text(
              'Xác thực FaceMatch khi GD > 10 triệu',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            subtitle: const Text(
              'Bắt buộc theo QĐ 2345/QĐ-NHNN để đối soát khuôn mặt với chip CCCD',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            onChanged: (v) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Quy định 2345/QĐ-NHNN là bắt buộc đối với mọi giao dịch chuyển tiền trên 10 triệu đồng.'),
                ),
              );
            },
          ),
          _buildDivider(),
          SwitchListTile.adaptive(
            value: _biometricLogin,
            activeTrackColor: AppColors.bottomBarCyan,
            title: const Text(
              'Đăng nhập nhanh bằng FaceID / Vân tay',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            subtitle: const Text(
              'Sử dụng cảm biến sinh trắc học tích hợp trên thiết bị',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _biometricLogin = v);
            },
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              onTap: () => context.push('/profile/ekyc'),
              leading: const Icon(CupertinoIcons.camera_viewfinder,
                  color: AppColors.bottomBarCyan, size: 22),
              title: const Text(
                'Cập nhật lại khuôn mặt & chip CCCD (eKYC)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'Quét lại chip NFC khi vừa được cấp thẻ CCCD gắn chip mới',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSelectorCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: List.generate(_thresholdLabels.length, (idx) {
          final isSelected = _selectedBioThresholdIdx == idx;
          return Column(
            children: [
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedBioThresholdIdx = idx);
                  },
                  title: Text(
                    _thresholdLabels[idx],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                  ),
                  trailing: Icon(
                    isSelected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: isSelected
                        ? AppColors.bottomBarCyan
                        : Colors.white24,
                    size: 18,
                  ),
                ),
              ),
              if (idx < _thresholdLabels.length - 1) _buildDivider(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGeoFencingCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vùng An Toàn Địa Lý (Geo-Fencing)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _geoFencingProtection
                            ? 'Đang chặn các IP và giao dịch ngoài lãnh thổ Việt Nam'
                            : 'Đang cho phép giao dịch quốc tế toàn cầu',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _geoFencingProtection,
                  activeTrackColor: AppColors.bottomBarCyan,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _geoFencingProtection = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.airplane,
                      color: AppColors.accentGold, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Khi xuất cảnh ra nước ngoài, hãy tắt tính năng này để giao dịch bình thường.',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessControlCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _twoFactorAuth,
            activeTrackColor: AppColors.bottomBarCyan,
            title: const Text(
              'Xác thực 2 lớp (2FA)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            subtitle: const Text(
              'Yêu cầu Smart OTP khi đăng nhập từ thiết bị lạ',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _twoFactorAuth = v);
            },
          ),
          _buildDivider(),
          SwitchListTile.adaptive(
            value: _pinLockApp,
            activeTrackColor: AppColors.bottomBarCyan,
            title: const Text(
              'Tự động khóa app khi rời màn hình',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            subtitle: const Text(
              'Yêu cầu FaceID hoặc PIN mỗi khi mở lại ứng dụng',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _pinLockApp = v);
            },
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              onTap: () => context.push('/settings/devices'),
              leading: const Icon(CupertinoIcons.device_phone_portrait,
                  color: AppColors.bottomBarCyan, size: 22),
              title: const Text(
                'Quản lý thiết bị đăng nhập (2 Thiết bị)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'iPhone 15 Pro (Hiện tại) • iPad Air M2',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: [
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              title: const Text(
                'Đổi mật khẩu đăng nhập',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'Nên đổi mật khẩu định kỳ 90 ngày để an toàn tài khoản',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
              onTap: _showChangePasswordModal,
            ),
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              title: const Text(
                'Đổi mã PIN giao dịch 6 số',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'Mã PIN bảo mật dùng để ký duyệt mọi lệnh chuyển và rút tiền',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
              onTap: () => context.push('/settings/change-pin'),
            ),
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              title: const Text(
                'Quên mã PIN giao dịch?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.bottomBarCyan,
                ),
              ),
              subtitle: const Text(
                'Xác minh Face Match để cấp lại mã PIN trực tuyến tức thì',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
              onTap: () => context.push('/auth/forgot-pin'),
            ),
          ),
          _buildDivider(),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              title: const Text(
                'Xác thực Chip CCCD qua NFC',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              subtitle: const Text(
                'Đọc chip bảo mật C06 BCA theo chuẩn Quyết định 2345',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.white38, size: 16),
              onTap: () => context.push('/profile/nfc-reader'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAuditLogCard() {
    final auditLogs = [
      {'title': 'Quét quyền trợ năng (Accessibility)', 'status': 'AN TOÀN', 'time': 'Hôm nay - 14:30'},
      {'title': 'Kiểm tra phần mềm quay lén màn hình', 'status': 'KHÔNG CÓ', 'time': 'Hôm qua - 09:15'},
      {'title': 'Kiểm tra Root / Magisk / Jailbreak', 'status': 'CHUẨN GỐC', 'time': '01/09/2026'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: auditLogs.map((log) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['title']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      log['time']!,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log['status']!,
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmergencyLockButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        onTap: _showEmergencyLockDialog,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(CupertinoIcons.lock_shield_fill,
              color: AppColors.error, size: 22),
        ),
        title: const Text(
          'Khóa Khẩn Cấp Toàn Bộ Tài Khoản & Thẻ',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        subtitle: const Text(
          'Kích hoạt trong 30 giây khi nghi ngờ bị lừa đảo hoặc thất lạc máy',
          style: TextStyle(fontSize: 11, color: Colors.white54),
        ),
        trailing: const Icon(CupertinoIcons.chevron_forward,
            color: AppColors.error, size: 16),
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
