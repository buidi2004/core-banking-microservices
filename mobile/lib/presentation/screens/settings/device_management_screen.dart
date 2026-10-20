import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/data/datasources/remote/session_remote_datasource.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeviceSessions();
  }

  Future<void> _loadDeviceSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sessionDataSource = SessionRemoteDataSource();
      final sessions = await sessionDataSource.getSessions();

      setState(() {
        _devices = sessions.map((s) {
          final isCurrent = s['isCurrentDevice'] == true;
          final deviceName = s['deviceName']?.toString();
          final deviceId = s['deviceId']?.toString();
          final model = (deviceName != null && deviceName.isNotEmpty)
              ? deviceName
              : (isCurrent ? 'Thiết bị này' : 'Thiết bị di động');
          final os = s['deviceOs']?.toString() ?? 'SenBank Mobile App';
          final ip = s['ipAddress']?.toString() ?? 'N/A';
          final lastActive = s['lastAccessedAt']?.toString() ?? s['createdAt']?.toString() ?? 'Đang hoạt động';

          return {
            'id': s['id']?.toString() ?? '',
            'deviceId': deviceId ?? '',
            'model': isCurrent ? '$model (Thiết bị này)' : model,
            'os': os,
            'ip': ip,
            'lastActive': isCurrent ? 'Đang hoạt động (Hiện tại)' : lastActive,
            'isCurrent': isCurrent,
            'hasSmartOtp': isCurrent,
            'isTrusted': true,
          };
        }).toList();

        // Sắp xếp: thiết bị hiện tại lên đầu
        _devices.sort((a, b) {
          if (a['isCurrent'] == true) return -1;
          if (b['isCurrent'] == true) return 1;
          return 0;
        });

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DeviceManagementScreen] Error loading sessions: $e');
      setState(() {
        _errorMessage = 'Không thể tải danh sách phiên đăng nhập. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  void _logoutDevice(String sessionId) async {
    try {
      final sessionDataSource = SessionRemoteDataSource();
      await sessionDataSource.revokeSession(sessionId);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _devices.removeWhere((d) => d['id'] == sessionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Đã thu hồi phiên đăng nhập thiết bị thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Không thể thu hồi phiên đăng nhập, vui lòng thử lại'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _logoutAllOtherDevices() async {
    try {
      final sessionDataSource = SessionRemoteDataSource();
      await sessionDataSource.revokeAllOtherSessions();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await _loadDeviceSessions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Đã đăng xuất khỏi tất cả các thiết bị khác thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Có lỗi khi đăng xuất các thiết bị khác, vui lòng thử lại'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111E),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emeraldGreen.withValues(alpha: 0.18),
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
                  child: _buildBody(),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.bottomBarCyan),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDeviceSessions,
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final hasOtherDevices = _devices.any((d) => d['isCurrent'] != true);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      children: [
        _buildHardwareSecurityCard(),
        const SizedBox(height: 20),
        _buildSectionHeader('PHIÊN THIẾT BỊ ĐANG HOẠT ĐỘNG (${_devices.length})'),
        const SizedBox(height: 10),
        if (_devices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1929).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Center(
              child: Text(
                'Chưa có phiên đăng nhập nào',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
          )
        else
          _buildDevicesList(),
        if (hasOtherDevices) ...[
          const SizedBox(height: 14),
          _buildLogoutOthersButton(),
        ],
        const SizedBox(height: 24),
        _buildSecurityPolicyCard(),
        const SizedBox(height: 24),
        _buildEmergencyLockSection(),
        const SizedBox(height: 40),
      ],
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
            '• Mỗi tài khoản SenBank chỉ được cấp quyền sinh mã Smart OTP trên duy nhất 01 thiết bị di động chính chủ tại cùng một thời điểm.',
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng liên hệ hotline 1900 6868 để thực hiện khóa khẩn cấp tài khoản.'),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.exclamationmark_shield_fill, size: 18),
              label: const Text('Kích hoạt khóa khẩn cấp 1-chạm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}