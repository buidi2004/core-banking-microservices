import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _loginHistory = [];

  @override
  void initState() {
    super.initState();
    _initDeviceData();
  }

  void _initDeviceData() {
    String model = 'Thiết bị đang sử dụng (Thiết bị này)';
    String os = 'Sen Hồng Mobile App v2.4.0';
    if (Platform.isAndroid) {
      model = 'Samsung Galaxy S24 Ultra (Thiết bị này)';
      os = 'Android 14 • One UI 6.1 • SenBank Mobile';
    } else if (Platform.isIOS) {
      model = 'iPhone 15 Pro Max (Thiết bị này)';
      os = 'iOS 18.0 • FaceID Ready • SenBank Mobile';
    } else if (Platform.isWindows) {
      model = 'Máy tính cá nhân Windows (Thiết bị này)';
      os = 'Windows 11 Pro • SenBank Desktop App';
    } else if (Platform.isMacOS) {
      model = 'Apple MacBook Pro M3 (Thiết bị này)';
      os = 'macOS Sonoma • TouchID Ready';
    }

    setState(() {
      _devices = [
        {
          'id': 'd1',
          'model': model,
          'os': os,
          'ip': '113.161.72.48 (Hà Nội, VN)',
          'lastActive': 'Đang hoạt động (Hiện tại)',
          'isCurrent': true,
          'hasSmartOtp': true,
          'isTrusted': true,
        },
        {
          'id': 'd2',
          'model': 'Apple iPad Air M2 11-inch',
          'os': 'iPadOS 17.5 • FaceID Ready',
          'ip': '14.162.19.102 (TP. Hồ Chí Minh, VN)',
          'lastActive': 'Hoạt động 3 giờ trước',
          'isCurrent': false,
          'hasSmartOtp': false,
          'isTrusted': true,
        },
      ];

      _loginHistory = [
        {
          'device': model.replaceAll(' (Thiết bị này)', ''),
          'time': '14:28 - Hôm nay',
          'location': 'Hà Nội, Việt Nam (113.161.72.48)',
          'channel': 'SenBank App (Sinh trắc học)',
          'isSuccess': true,
        },
        {
          'device': 'Apple iPad Air M2',
          'time': '11:15 - Hôm nay',
          'location': 'TP. Hồ Chí Minh, Việt Nam (14.162.19.102)',
          'channel': 'SenBank App (Mã PIN 6 số)',
          'isSuccess': true,
        },
        {
          'device': 'Google Chrome trên Windows',
          'time': '09:04 - 05/09/2026',
          'location': 'Hà Nội, Việt Nam (113.161.72.48)',
          'channel': 'Web Banking (QR Code Login)',
          'isSuccess': true,
        },
        {
          'device': 'Thiết bị lạ (Firefox trên Linux)',
          'time': '23:14 - 02/09/2026',
          'location': 'Singapore (128.199.204.11)',
          'channel': 'Web Banking • ĐÃ CHẶN TỰ ĐỘNG',
          'isSuccess': false,
        },
      ];
    });
  }

  void _logoutDevice(String id) {
    HapticFeedback.mediumImpact();
    setState(() => _devices.removeWhere((d) => d['id'] == id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đã thu hồi quyền truy cập và đăng xuất thiết bị!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logoutAllOtherDevices() {
    HapticFeedback.heavyImpact();
    setState(() => _devices.removeWhere((d) => !d['isCurrent']));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đã đăng xuất khỏi tất cả các thiết bị khác!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _lockAccountEmergency() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Khóa Khẩn Cấp Tài Khoản?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động này sẽ ngay lập tức:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text('• Hủy tất cả phiên đăng nhập trên mọi thiết bị', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text('• Tạm khóa Smart OTP và tính năng chuyển tiền', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text('• Gửi SMS cảnh báo đến số điện thoại đăng ký', style: TextStyle(color: Colors.white60, fontSize: 12)),
            SizedBox(height: 12),
            Text(
              'Để mở lại tài khoản, bạn cần gọi Hotline 1900 6688 hoặc đến quầy giao dịch SenBank.',
              style: TextStyle(color: AppColors.accentGold, fontSize: 11.5, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('Đã kích hoạt khóa tài khoản khẩn cấp thành công!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Xác nhận khóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B17),
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bottomBarCyan.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      _buildHardwareSecurityCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('PHIÊN THIẾT BỊ ĐANG HOẠT ĐỘNG (${_devices.length})'),
                      const SizedBox(height: 10),
                      _buildDevicesList(),
                      const SizedBox(height: 14),
                      _buildLogoutOthersButton(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('NHẬT KÝ ĐĂNG NHẬP 7 NGÀY GẦN NHẤT'),
                      const SizedBox(height: 10),
                      _buildLoginHistoryList(),
                      const SizedBox(height: 24),
                      _buildSecurityPolicyCard(),
                      const SizedBox(height: 24),
                      _buildEmergencyLockSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030B17).withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý thiết bị',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                Text(
                  'Kiểm soát phiên đăng nhập & Smart OTP',
                  style: TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.shield_fill, color: AppColors.emeraldGreen, size: 14),
                SizedBox(width: 4),
                Text('AN TOÀN', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102847),
            Color(0xFF0F2B48),
            Color(0xFF071526),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Bảo Mật Phần Cứng Thiết Bị',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ],
              ),
              Text(
                'TIÊU CHUẨN FIPS 140-2',
                style: TextStyle(color: AppColors.accentGold, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildHardwareDetail('Mã hóa phần cứng:', 'Secure Enclave / Android Keystore'),
          _buildHardwareDetail('Cấp độ mật mã:', 'AES-256 GCM + Khóa bất đối xứng RSA-4096'),
          _buildHardwareDetail('Trạng thái hệ điều hành:', 'Nguyên bản (Không Root / Jailbreak)', isGreen: true),
          _buildHardwareDetail('Chứng chỉ bảo mật Smart OTP:', 'SENBANK-HARDWARE-TOKEN-VALID'),
        ],
      ),
    );
  }

  Widget _buildHardwareDetail(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isGreen ? AppColors.emeraldGreen : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
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

  Widget _buildDevicesList() {
    return Column(
      children: _devices.map((d) {
        final isCurrent = d['isCurrent'] as bool;
        final hasSmartOtp = d['hasSmartOtp'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF132845)
                : const Color(0xFF0C1929).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? AppColors.bottomBarCyan.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.bottomBarCyan.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCurrent ? CupertinoIcons.device_phone_portrait : CupertinoIcons.device_laptop,
                      color: isCurrent ? AppColors.bottomBarCyan : Colors.white70,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['model'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['os'] as String,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrent)
                    IconButton(
                      icon: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 20),
                      onPressed: () => _logoutDevice(d['id'] as String),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('HIỆN TẠI', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.location_solid, color: Colors.white38, size: 13),
                        const SizedBox(width: 4),
                        Text(d['ip'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    Text(
                      d['lastActive'] as String,
                      style: TextStyle(
                        color: isCurrent ? AppColors.emeraldGreen : AppColors.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSmartOtp) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(CupertinoIcons.lock_shield_fill, color: AppColors.bottomBarCyan, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Đã liên kết Smart OTP • Khóa bảo mật phần cứng duy nhất',
                      style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoutOthersButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _logoutAllOtherDevices,
        icon: const Icon(CupertinoIcons.xmark_shield_fill, color: Colors.redAccent, size: 18),
        label: const Text(
          'Đăng xuất khỏi tất cả các thiết bị khác',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildLoginHistoryList() {
    return Column(
      children: _loginHistory.map((item) {
        final isSuccess = item['isSuccess'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1929).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSuccess
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.redAccent.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? CupertinoIcons.checkmark_alt : CupertinoIcons.clear,
                  color: isSuccess ? AppColors.emeraldGreen : Colors.redAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['device'] as String,
                      style: TextStyle(
                        color: isSuccess ? Colors.white : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['time']} • ${item['channel']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['location'] as String,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSecurityPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.info_circle_fill, color: AppColors.bottomBarCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Chính sách tuân thủ Thông tư 50/TT-NHNN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Mỗi tài khoản SenBank chỉ được cấp quyền sinh mã Smart OTP trên duy nhất 01 thiết bị di động chính chủ tại cùng một thời điểm.\n'
            '• Khi đăng nhập trên thiết bị mới, hệ thống sẽ yêu cầu xác thực khuôn mặt sinh trắc học khớp với chip CCCD (QĐ 2345/QĐ-NHNN).',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyLockSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.lock_shield_fill, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Quy trình khẩn cấp khi thất lạc thiết bị',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Nếu nghi ngờ điện thoại bị mất hoặc có người xâm nhập, hãy kích hoạt khóa khẩn cấp ngay để bảo toàn 100% số dư và tài sản ngân hàng.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _lockAccountEmergency,
              icon: const Icon(CupertinoIcons.exclamationmark_shield_fill, size: 18),
              label: const Text('Kích hoạt khóa khẩn cấp 1-chạm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
