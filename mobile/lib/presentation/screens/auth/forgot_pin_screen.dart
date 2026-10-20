import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  int _currentStep = 1; // 1: OTP, 2: New PIN
  final TextEditingController _otpCtrl = TextEditingController();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length < 6) {
      AppAlerts.showWarning(
        context,
        'Vui lòng nhập đủ 6 chữ số mã OTP xác thực',
        title: 'Mã OTP chưa đủ',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = await AppSecureStorage.safeRead(AppSecureStorage.instance, key: AppConstants.keyPhoneNumber);
      if (phone == null || phone.isEmpty) throw Exception('Thiếu số điện thoại xác minh');
      final verified = await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).verifyOtp(phoneNumber: phone, otp: _otpCtrl.text);
      if (!verified) throw Exception('Mã OTP không chính xác');
      if (mounted) setState(() => _currentStep = 2);
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Xác minh OTP thất bại',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleKeyPress(String value) {
    if (!_isConfirming) {
      if (_pin.length < 6) {
        setState(() => _pin += value);
        if (_pin.length == 6) {
          setState(() => _isConfirming = true);
        }
      }
    } else {
      if (_confirmPin.length < 6) {
        setState(() => _confirmPin += value);
        if (_confirmPin.length == 6) {
          _submitNewPin();
        }
      }
    }
  }

  void _handleBackspace() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _submitNewPin() async {
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Mã PIN xác nhận không khớp! Vui lòng nhập lại.'),
        ),
      );
      setState(() {
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    if (_pin == '123456' || _pin == '000000' || _pin == '111111') {
      AppAlerts.showWarning(
        context,
        'Mã PIN quá đơn giản. Quý khách vui lòng chọn mã khác để bảo mật tài khoản.',
        title: 'Mã PIN không an toàn',
      );
      setState(() {
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).setPin(_pin);
      if (!mounted) return;
      AppAlerts.showSuccess(
        context,
        'Cấp lại mã PIN mới thành công!',
        title: 'Thành công',
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/settings/security');
      }
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Cài đặt mã PIN thất bại',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cấp Lại Mã PIN'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              const InlineWarningBanner(
                title: 'Bảo mật mã PIN thanh toán',
                message: 'Mã PIN 6 số là khóa xác thực cho toàn bộ giao dịch ví SenBank. Không chia sẻ mã PIN cho bất kỳ ai và tránh sử dụng ngày tháng năm sinh.',
                type: AlertType.warning,
              ),
              const SizedBox(height: 18),
              _currentStep == 1 ? _buildOtpStep() : _buildPinStep(),
              const SizedBox(height: 20),

              // Auth Navigation Router Hub
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                        label: 'Quên mật khẩu đăng nhập? Khôi phục mật khẩu',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Quay lại trang Thiết lập mã PIN',
                        onTap: () => context.push('/auth/set-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: 'Quay lại màn hình Đăng nhập',
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
                        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                        label: 'Xác thực khuôn mặt eKYC để cấp lại PIN',
                        onTap: () => context.push('/profile/ekyc'),
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
                        label: 'Hỗ trợ khách hàng 24/7 (Hotline 1900 6868)',
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

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primary, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Text('Xác minh danh tính', style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Hệ thống đã gửi mã xác thực OTP 6 số đến số điện thoại đăng ký tài khoản của bạn để xác thực yêu cầu cấp lại mã PIN.',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 24),

        Text('Mã OTP xác thực', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: AppColors.primaryDark, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: const TextStyle(color: AppColors.textMutedLight, letterSpacing: 6),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            child: const Text('Xác nhận OTP & Bước tiếp theo'),
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    final activeLength = _isConfirming ? _confirmPin.length : _pin.length;
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          _isConfirming ? 'Xác nhận lại mã PIN mới' : 'Thiết lập mã PIN mới',
          style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _isConfirming ? 'Nhập lại 6 chữ số để hoàn tất xác thực' : 'Mã PIN gồm 6 số dùng để ký chuyển tiền & thanh toán',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 24),

        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < activeLength;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isFilled ? AppColors.primary : AppColors.textMutedLight,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),

        // Custom Numpad Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            if (index == 9) return const SizedBox.shrink();
            if (index == 11) {
              return InkWell(
                onTap: _handleBackspace,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(CupertinoIcons.delete_left, color: AppColors.textPrimaryLight, size: 22),
                ),
              );
            }
            final digit = index == 10 ? '0' : '${index + 1}';
            return InkWell(
              onTap: () => _handleKeyPress(digit),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    digit,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                  ),
                ),
              ),
            );
          },
        ),

        if (_isLoading) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ],
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
