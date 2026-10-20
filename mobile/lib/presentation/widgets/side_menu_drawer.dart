import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'user_avatar_widget.dart';

class SideMenuDrawer extends StatefulWidget {
  final String? displayName;
  final String? accountNumber;

  const SideMenuDrawer({super.key, this.displayName, this.accountNumber});

  @override
  State<SideMenuDrawer> createState() => _SideMenuDrawerState();
}

class _SideMenuDrawerState extends State<SideMenuDrawer> {
  String _displayName = '';
  String _accountNumber = '';

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName ?? '';
    _accountNumber = widget.accountNumber ?? '';
    if (_displayName.isEmpty || _accountNumber.isEmpty) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.keyAccessToken);
      if (token == null || token.isEmpty) return;

      final savedPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (savedPhone != null && savedPhone.isNotEmpty && mounted && _accountNumber.isEmpty) {
        setState(() => _accountNumber = savedPhone);
      }

      final profile = await ProfileRemoteDataSource().getMe();
      if (!mounted) return;
      setState(() {
        if (_displayName.isEmpty) {
          _displayName = profile['fullName'] as String? ?? '';
        }
        final phone = profile['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          _accountNumber = phone;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = _displayName.isNotEmpty ? _displayName : 'Quý khách';
    final sub = _accountNumber.isNotEmpty ? '$_accountNumber • STK: $_accountNumber' : 'Ví Sen Hồng';

    return Drawer(
      backgroundColor: AppColors.textPrimaryLight,
      child: SafeArea(
        child: Column(
          children: [
            // Header User Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.balanceCardGradient.colors.first, AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.bottomBarCyan.withOpacity(0.4), width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      UserAvatarWidget(
                        radius: 28,
                        borderColor: Colors.white38,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/profile');
                        },
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleLarge(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: AppTypography.bodySmall(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/kyc-level');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'Đã Định Danh eKYC Cấp 2',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildItem(
                    context,
                    icon: CupertinoIcons.person_fill,
                    title: 'Hồ sơ cá nhân',
                    route: '/profile',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.shield_fill,
                    title: 'Cài đặt bảo mật & Smart OTP',
                    route: '/settings/security',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.creditcard_fill,
                    title: 'Quản lý thẻ & Nguồn tiền',
                    route: '/payment-methods',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.building_2_fill,
                    title: 'Tài khoản ngân hàng liên kết',
                    route: '/bank-cards',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.person_2_fill,
                    title: 'Danh bạ người thụ hưởng',
                    route: '/beneficiaries',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.device_phone_portrait,
                    title: 'Quản lý thiết bị đăng nhập',
                    route: '/settings/devices',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.gift_fill,
                    title: 'Giới thiệu bạn bè nhận thưởng',
                    route: '/referral',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.gear_alt_fill,
                    title: 'Giao diện & Cài đặt app',
                    route: '/settings',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.sparkles,
                    title: 'Hiệu ứng mở app Hoa Sen Nở',
                    route: '/splash',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.gear_alt_fill,
                    title: 'Cấu hình Server API',
                    route: '/settings/config',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.phone_circle_fill,
                    title: 'Trợ giúp & Live Chat CSKH',
                    route: '/support/help-center',
                  ),
                  _buildItem(
                    context,
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Điều khoản dịch vụ & Pháp lý',
                    route: '/auth/terms',
                  ),
                ],
              ),
            ),

            // Footer Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  minimumSize: const Size(double.infinity, 46),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  const storage = FlutterSecureStorage();
                  await storage.delete(key: AppConstants.keyAccessToken);
                  await storage.delete(key: AppConstants.keyRefreshToken);
                  await storage.delete(key: AppConstants.keyPinToken);
                  await storage.delete(key: AppConstants.keyWalletId);
                  if (context.mounted) {
                    context.go('/auth/login');
                  }
                },
                icon: const Icon(CupertinoIcons.square_arrow_right_fill, size: 18),
                label: const Text('Đăng xuất tài khoản'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Material(type: MaterialType.transparency, child: ListTile(
      leading: Icon(icon, color: AppColors.primaryLight, size: 20),
      title: Text(title, style: AppTypography.bodyMedium(color: Colors.white)),
      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedDark, size: 14),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    ));
  }
}
