import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phone;

  const OtpVerificationScreen({super.key, this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otp = '';
  bool _isSmartOtp = false;
  bool _isVerifying = false;

  Future<void> _onOtpChanged(String value) async {
    setState(() => _otp = value);
    if (value.length == 6) {
      if (_isVerifying) return;
      setState(() => _isVerifying = true);
      try {
        if (!mounted) return;
        await showFeatureUnavailable(
          context,
          feature: 'Xác thực OTP',
          reason: 'Backend chưa cung cấp API xác thực OTP (BE-REQ-04). '
                  'Vui lòng quay lại màn hình đăng nhập hoặc đăng ký.',
        );
        if (!mounted) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/auth/register');
        }
        return;
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.phone;
    final displayPhone = (p != null && p.length >= 7)
        ? '${p.substring(0, 3)} ••• ${p.substring(p.length - 3)}'
        : (p != null && p.isNotEmpty ? p : 'Số điện thoại đăng ký');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Thực Bảo Mật OTP'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Banner BE-REQ-04
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, color: AppColors.accentGold, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tính năng xác thực OTP qua SMS/Voice chưa được hỗ trợ trên hệ thống máy chủ (BE-REQ-04). Vui lòng đăng nhập hoặc đăng ký trực tiếp.',
                        style: TextStyle(color: AppColors.warningText, fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Method toggle: SMS OTP vs Smart OTP
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSmartOtp = false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isSmartOtp ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isSmartOtp
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.chat_bubble_text_fill, size: 16, color: !_isSmartOtp ? AppColors.primary : AppColors.textSecondaryLight),
                              const SizedBox(width: 6),
                              Text('SMS OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !_isSmartOtp ? AppColors.primary : AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _isSmartOtp = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chế độ Smart OTP: Mã sinh tự động bảo mật cao theo chuẩn PKI.')),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSmartOtp ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isSmartOtp
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.shield_lefthalf_fill, size: 16, color: _isSmartOtp ? AppColors.primary : AppColors.textSecondaryLight),
                              const SizedBox(width: 6),
                              Text('Smart OTP PKI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isSmartOtp ? AppColors.primary : AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSmartOtp ? CupertinoIcons.lock_shield_fill : CupertinoIcons.device_phone_portrait,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Nhập Mã Xác Thực 6 Số', style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                _isSmartOtp
                    ? 'Mã bảo mật Smart OTP được sinh tự động trên thiết bị chính chủ của bạn'
                    : 'Mã xác thực một lần (OTP) đã gửi qua SMS tới số $displayPhone',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 14),

              // Anti-fraud security warning banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'CẢNH BÁO: Ngân hàng KHÔNG BAO GIỜ yêu cầu cung cấp OTP. Tuyệt đối không chia sẻ mã này cho bất kỳ ai!',
                        style: TextStyle(fontSize: 11, color: AppColors.errorText, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // PIN Numpad (Disabled visually & functionally via BE-REQ-04 notification)
              CustomPinNumpad(
                pin: _otp,
                maxDigits: 6,
                onPinChanged: _onOtpChanged,
              ),
              const SizedBox(height: 16),

              // Resend & Voice OTP actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => showFeatureUnavailable(context, feature: 'Gửi lại OTP', reason: 'BE-REQ-04: Backend chưa hỗ trợ SMS OTP gateway.'),
                    icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 16),
                    label: const Text(
                      'Gửi lại mã OTP SMS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: AppColors.textSecondaryLight)),
                  TextButton.icon(
                    onPressed: () => showFeatureUnavailable(context, feature: 'Cuộc gọi OTP', reason: 'BE-REQ-04: Backend chưa hỗ trợ Voice OTP service.'),
                    icon: const Icon(CupertinoIcons.phone_arrow_up_right, size: 16),
                    label: const Text('Nhận cuộc gọi OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quay lại Đăng nhập button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/auth/login');
                    }
                  },
                  icon: const Icon(CupertinoIcons.arrow_left, size: 18),
                  label: const Text('Quay lại Đăng nhập'),
                ),
              ),
              const SizedBox(height: 12),

              // Về Trang Chủ button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(CupertinoIcons.home, size: 18),
                  label: const Text('Về Trang Chủ'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                  ),
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
                        icon: CupertinoIcons.pencil_circle_fill,
                        label: 'Đổi số điện thoại / Sửa thông tin đăng ký',
                        onTap: () => context.push('/auth/register'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: 'Quay lại màn hình Đăng nhập',
                        onTap: () => context.go('/auth/login'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_circle_fill,
                        label: 'Quên mật khẩu? Khôi phục mật khẩu',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Quên mã PIN giao dịch? Cấp lại mã PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Xem Điều khoản dịch vụ & Quy định bảo mật',
                        onTap: () => context.push('/auth/terms'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Không nhận được OTP? Hotline CSKH 1900 6688',
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