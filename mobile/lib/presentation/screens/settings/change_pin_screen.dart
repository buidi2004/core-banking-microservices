import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _currentStep = 1; // 1: Nhập PIN cũ, 2: Nhập PIN mới, 3: Xác nhận PIN mới
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _isLoading = false;
  String? _errorMessage;

  String get _currentPin {
    if (_currentStep == 1) return _oldPin;
    if (_currentStep == 2) return _newPin;
    return _confirmPin;
  }

  void _onKeyPress(String digit) {
    HapticFeedback.selectionClick();
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (_currentStep == 1 && _oldPin.length < 6) {
        _oldPin += digit;
        if (_oldPin.length == 6) _verifyOldPin();
      } else if (_currentStep == 2 && _newPin.length < 6) {
        _newPin += digit;
        if (_newPin.length == 6) _proceedToStep3();
      } else if (_currentStep == 3 && _confirmPin.length < 6) {
        _confirmPin += digit;
        if (_confirmPin.length == 6) _submitChangePin();
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (_currentStep == 1 && _oldPin.isNotEmpty) {
        _oldPin = _oldPin.substring(0, _oldPin.length - 1);
      } else if (_currentStep == 2 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_currentStep == 3 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  Future<void> _verifyOldPin() async {
    // MOB-007 / R2-P1-03 (vòng 2): backend chưa có API xác thực PIN (BE-REQ-03).
    // Phải gate TRƯỚC khi gọi API, nếu không người dùng sẽ bị báo nhầm
    // "Mã PIN hiện tại chưa chính xác" trong khi thực ra tính năng chưa tồn tại.
    if (!BackendCapabilities.transactionPin) {
      await showFeatureUnavailable(
        context,
        feature: 'Đổi mã PIN giao dịch',
        reason: 'Backend chưa hỗ trợ API xác thực mã PIN giao dịch (BE-REQ-03). '
            'Tính năng quản lý mã PIN máy chủ đang được nâng cấp.',
      );
      if (!mounted) return;
      setState(() {
        _oldPin = '';
        _errorMessage = 'Tính năng chưa sẵn sàng. Vui lòng quay lại sau.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await WalletTransactionRemoteDataSource().verifyPin(_oldPin);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } on UnsupportedError catch (e) {
      // Backend không có endpoint ⇒ không được báo nhầm "PIN sai".
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isLoading = false;
        _oldPin = '';
        _errorMessage = e.message ?? 'Tính năng chưa sẵn sàng. Vui lòng quay lại sau.';
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isLoading = false;
        _oldPin = '';
        _errorMessage = 'Mã PIN hiện tại chưa chính xác. Quý khách vui lòng thử lại.';
      });
    }
  }

  void _proceedToStep3() {
    if (_newPin == _oldPin) {
      HapticFeedback.vibrate();
      setState(() {
        _newPin = '';
        _errorMessage = 'Mã PIN mới không được trùng với mã PIN hiện tại.';
      });
      return;
    }
    // Kiểm tra tính bảo mật cơ bản: không được 6 số liên tiếp hoặc giống hệt nhau
    if (_newPin == '123456' || _newPin == '000000' || _newPin == '111111') {
      HapticFeedback.vibrate();
      setState(() {
        _newPin = '';
        _errorMessage = 'Mã PIN quá đơn giản. Quý khách vui lòng chọn mã khác để bảo vệ tài khoản.';
      });
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep = 3;
    });
  }

  Future<void> _submitChangePin() async {
    if (_confirmPin != _newPin) {
      HapticFeedback.vibrate();
      setState(() {
        _confirmPin = '';
        _errorMessage = 'Mã PIN xác nhận không khớp với mã PIN mới. Vui lòng nhập lại.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthRemoteDataSource().setPin(_newPin);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mã PIN giao dịch thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = 'Không thể đổi mã PIN: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String stepTitle = '';
    String stepDesc = '';
    if (_currentStep == 1) {
      stepTitle = 'Nhập mã PIN hiện tại';
      stepDesc = 'Xác thực chủ tài khoản để bắt đầu quá trình đổi mã PIN';
    } else if (_currentStep == 2) {
      stepTitle = 'Nhập mã PIN mới';
      stepDesc = 'Thiết lập mã PIN gồm 6 chữ số bảo mật cao';
    } else {
      stepTitle = 'Xác nhận mã PIN mới';
      stepDesc = 'Nhập lại mã PIN mới một lần nữa để hoàn tất';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Đổi Mã PIN Giao Dịch'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.shield_fill, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Để đảm bảo an toàn tài chính, không chia sẻ mã PIN cho bất kỳ ai.',
                              style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Step Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepNode(1, 'PIN cũ', isActive: _currentStep >= 1),
                        _buildStepLine(isDone: _currentStep >= 2),
                        _buildStepNode(2, 'PIN mới', isActive: _currentStep >= 2),
                        _buildStepLine(isDone: _currentStep >= 3),
                        _buildStepNode(3, 'Xác nhận', isActive: _currentStep >= 3),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title & Description
                    Text(
                      stepTitle,
                      style: AppTypography.titleLarge(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepDesc,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 24),

                    // 6 Dots PIN Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (idx) {
                        final isFilled = idx < _currentPin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 9),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isFilled ? AppColors.primaryGradient : null,
                            color: isFilled ? null : Colors.transparent,
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: AppColors.bottomBarGlow.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                            border: Border.all(
                              color: isFilled ? AppColors.bottomBarCyan : AppColors.borderLight,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Security Guidelines Card
                    GlassCard(
                      quality: GlassQuality.minimal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Quy tắc bảo mật mã PIN',
                                  style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildRuleItem('Không đặt mã PIN trùng ngày sinh hoặc số điện thoại'),
                            _buildRuleItem('Không dùng chuỗi số tăng dần hoặc giảm dần (123456, 654321)'),
                            _buildRuleItem('Không chia sẻ mã PIN cho bất kỳ ai, kể cả nhân viên ngân hàng'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: () => context.push('/auth/forgot-pin'),
                      icon: const Icon(CupertinoIcons.mail_solid, size: 16),
                      label: const Text('Quên mã PIN hiện tại? Nhận OTP qua Gmail để cấp lại mã PIN'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              // Numpad Light Glass Layout
              Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
                child: Column(
                  children: [
                    _buildNumpadRow(['1', '2', '3']),
                    const SizedBox(height: 12),
                    _buildNumpadRow(['4', '5', '6']),
                    const SizedBox(height: 12),
                    _buildNumpadRow(['7', '8', '9']),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 68, height: 68),
                        _buildNumpadBtn('0'),
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: IconButton(
                            icon: const Icon(CupertinoIcons.delete_left_fill, color: AppColors.primaryDark, size: 26),
                            onPressed: _onBackspace,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNode(int step, String label, {required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : AppColors.surfaceLight,
            border: Border.all(color: isActive ? AppColors.bottomBarCyan : AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMutedLight,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primaryDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isDone}) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      color: isDone ? AppColors.emeraldGreen : AppColors.borderLight,
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.check_mark, size: 14, color: AppColors.emeraldGreen),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildNumpadBtn(d)).toList(),
    );
  }

  Widget _buildNumpadBtn(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(34),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
