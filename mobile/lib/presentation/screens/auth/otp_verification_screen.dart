import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phone;

  const OtpVerificationScreen({super.key, this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otp = '';
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isSmartOtp = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onOtpChanged(String value) async {
    setState(() => _otp = value);
    if (value.length == 6) {
      if (_isVerifying) return;
      setState(() => _isVerifying = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final verified = await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).verifyOtp(
          phoneNumber: widget.phone ?? '',
          otp: value,
        );
        if (!verified) throw Exception('Mã OTP không chính xác');
        if (mounted) context.push('/auth/set-pin');
      } catch (error) {
        if (mounted) {
          AppAlerts.showError(
            context,
            extractErrorMessage(error),
            title: 'Xác thực OTP thất bại',
          );
        }
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).sendOtp(widget.phone ?? '');
      if (!mounted) return;
      _startTimer();
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Không thể gửi lại OTP',
        );
      }
      return;
    }
    if (!mounted) return;
    AppAlerts.showSuccess(
      context,
      'Đã gửi lại mã OTP 6 số mới qua tin nhắn SMS!',
      title: 'Đã gửi mã',
    );
  }

  void _requestVoiceOtp() {
    AppAlerts.showInfo(
      context,
      'Tổng đài tự động SenBank đang kết nối đến số điện thoại của quý khách để đọc mã xác thực...',
      title: 'Xác thực qua cuộc gọi',
    );
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

              // PIN Numpad
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
                    onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                    icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 16),
                    label: Text(
                      _secondsRemaining > 0 ? 'Gửi lại OTP ($_secondsRemaining s)' : 'Gửi lại mã OTP SMS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining > 0 ? AppColors.textSecondaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: AppColors.textSecondaryLight)),
                  TextButton.icon(
                    onPressed: _requestVoiceOtp,
                    icon: const Icon(CupertinoIcons.phone_arrow_up_right, size: 16),
                    label: const Text('Nhận cuộc gọi OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _otp.length == 6 ? () => context.push('/auth/set-pin') : null,
                  child: const Text('Xác nhận & Thiết lập mã PIN'),
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
                        label: 'Xem Điều khoản dịch vụ & Chính sách NHNN',
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

