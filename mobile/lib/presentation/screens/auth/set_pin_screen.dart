import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/network/permission_service.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String? _firstPin;
  bool _isConfirm = false;
  bool _isSubmitting = false;

  void _onPinChanged(String value) async {
    if (_isSubmitting) return;
    setState(() => _pin = value);
    if (value.length == 6) {
      if (!_isConfirm) {
        // Chuyển sang bước nhập lại PIN
        setState(() {
          _firstPin = value;
          _pin = '';
          _isConfirm = true;
        });
      } else {
        if (_pin == _firstPin) {
          // Thành công -> Lưu PIN lên server và Vào Trang Chủ
          setState(() => _isSubmitting = true);
          try {
            final prefs = await SharedPreferences.getInstance();
            await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).setPin(_pin);
          } catch (_) {}
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.emeraldGreen,
              content: Text('Thiết lập mã PIN giao dịch thành công!'),
            ),
          );
          // Xin cấp quyền hệ thống sau khi đăng ký và tạo mã PIN thành công
          unawaited(PermissionService().requestAllAppPermissions());
          context.go('/');
        } else {
          // Không khớp -> Làm lại
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã PIN xác nhận không khớp, vui lòng thử lại'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _pin = '';
            _firstPin = null;
            _isConfirm = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Thiết Lập Mã PIN'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Registration Steps Tracker (Step 2: Tạo mã PIN)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, 'Thông tin', isActive: false, isDone: true),
                  _buildStepConnector(isDone: true),
                  _buildStepIndicator(2, 'Tạo mã PIN', isActive: true, isDone: false),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primary, size: 30),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isConfirm ? 'Xác nhận lại mã PIN' : 'Tạo mã PIN giao dịch',
                style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isConfirm
                    ? 'Nhập lại 6 chữ số vừa tạo để hoàn tất xác thực'
                    : 'Mã PIN gồm 6 số dùng để ký duyệt mọi giao dịch chuyển tiền & thanh toán',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 20),

              // PIN Numpad
              CustomPinNumpad(
                pin: _pin,
                maxDigits: 6,
                onPinChanged: _onPinChanged,
              ),
              const SizedBox(height: 16),

              // Security notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, color: AppColors.accentGold, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu ý: Không đặt mã PIN theo ngày sinh, số liên tiếp (123456) hoặc số trùng lặp để bảo vệ an toàn tài khoản.',
                        style: TextStyle(color: AppColors.warningText, fontSize: 11, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Auth Navigation Router Hub
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Quên mã PIN cũ? Lấy lại mã PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                        label: 'Quên mật khẩu đăng nhập? Khôi phục',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_left_circle_fill,
                        label: 'Quay lại thông tin đăng ký',
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/auth/register');
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: 'Về màn hình Đăng nhập',
                        onTap: () => context.go('/auth/login'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        label: 'Chưa có tài khoản? Đăng ký ví mới',
                        onTap: () => context.push('/auth/register'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Điều khoản dịch vụ & Quy định bảo mật',
                        onTap: () => context.push('/auth/terms'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.home,
                        label: 'Bỏ qua, thiết lập mã PIN sau (Vào trang chủ)',
                        onTap: () => context.go('/'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Trung tâm trợ giúp bảo mật & CSKH 24/7',
                        onTap: () => context.push('/support/help-center'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, {required bool isActive, required bool isDone}) {
    final color = isDone ? AppColors.emeraldGreen : (isActive ? AppColors.primary : AppColors.textMutedLight);
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: color,
          child: isDone
              ? const Icon(CupertinoIcons.checkmark, size: 12, color: Colors.white)
              : Text('$step', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 36,
      height: 2,
      color: isDone ? AppColors.emeraldGreen : AppColors.borderSubtle,
    );
  }

  Widget _buildRouterTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 14),
          ],
        ),
      ),
    );
  }
}
