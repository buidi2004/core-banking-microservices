import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/core/network/push_notification_service.dart';
import 'package:sen_hong_bank/core/network/permission_service.dart';
import 'package:sen_hong_bank/core/network/realtime_notification_service.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';
import 'package:sen_hong_bank/presentation/widgets/app_morph_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sen_hong_bank/core/storage/app_session.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  final bool sessionExpired;
  final String? expiredMessage;

  const LoginScreen({
    super.key,
    this.sessionExpired = false,
    this.expiredMessage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isMaskedUser = false;
  String _accountName = '';
  bool _isLoading = false;
  late bool _showExpiredBanner;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _hasSavedBiometric = false;

  @override
  void initState() {
    super.initState();
    _showExpiredBanner = widget.sessionExpired;
    _loadSavedUser();
  }


  Future<void> _loadSavedUser() async {
    try {
      const storage = AppSecureStorage.instance;
      final savedPhone = await AppSecureStorage.safeRead(storage, key: AppConstants.keyPhoneNumber);
      final savedName = await AppSecureStorage.safeRead(storage, key: AppConstants.keyFullName);
      final savedPassword = await AppSecureStorage.safeRead(storage, key: 'biometric_saved_password');

      // Backup an toàn từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefPhone = prefs.getString('bio_saved_phone');
      final prefPwdEncoded = prefs.getString('bio_saved_pwd');
      String? fallbackPassword;
      if (prefPwdEncoded != null && prefPwdEncoded.isNotEmpty) {
        try {
          fallbackPassword = utf8.decode(base64Decode(prefPwdEncoded));
        } catch (_) {}
      }

      final effectivePhone = (savedPhone != null && savedPhone.isNotEmpty) ? savedPhone : prefPhone;
      final effectivePassword = (savedPassword != null && savedPassword.isNotEmpty) ? savedPassword : fallbackPassword;

      final existingToken = await AppSecureStorage.safeRead(storage, key: AppConstants.keyAccessToken);
      final hasToken = existingToken != null && existingToken.isNotEmpty;

      bool hasBio = false;
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        final hasPassword = effectivePassword != null && effectivePassword.isNotEmpty;
        hasBio = (canCheck || isSupported) && (hasToken || hasPassword);
      } catch (_) {}

      if (effectivePhone != null && effectivePhone.isNotEmpty) {
        _phoneController.text = effectivePhone;
        if (mounted) {
          setState(() {
            _isMaskedUser = true;
            _accountName = (savedName != null && savedName.isNotEmpty) ? savedName : 'Quý khách';
            _hasSavedBiometric = hasBio;
          });

          // FaceID chỉ được quét khi người dùng chủ động bấm nút FaceID
        }
      }
    } catch (_) {}
  }


  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = AuthLocalDataSourceImpl(prefs: prefs);
      await AuthRemoteDataSource(local: local).login(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        deviceId: 'flutter-${DateTime.now().millisecondsSinceEpoch}',
      );

      // Lưu hoặc xóa thông tin ghi nhớ an toàn (Keychain + SharedPreferences backup)
      const storage = AppSecureStorage.instance;
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      if (_rememberMe) {
        await AppSecureStorage.safeWrite(storage, key: AppConstants.keyPhoneNumber, value: phone);
        await AppSecureStorage.safeWrite(storage, key: 'biometric_saved_password', value: password);
        await AppSecureStorage.safeWrite(storage, key: AppConstants.keyBiometricEnabled, value: 'true');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bio_saved_phone', phone);
        await prefs.setString('bio_saved_pwd', base64Encode(utf8.encode(password)));
        await prefs.setBool('bio_enabled', true);
      } else {
        await AppSecureStorage.safeDelete(storage, key: AppConstants.keyPhoneNumber);
        await AppSecureStorage.safeDelete(storage, key: AppConstants.keyFullName);
        await AppSecureStorage.safeDelete(storage, key: 'biometric_saved_password');
        await AppSecureStorage.safeDelete(storage, key: AppConstants.keyBiometricEnabled);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('bio_saved_phone');
        await prefs.remove('bio_saved_pwd');
        await prefs.remove('bio_enabled');
      }

      // Đồng bộ FCM token với backend khi đăng nhập thành công
      final fcmToken = PushNotificationService().fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        unawaited(PushNotificationService().syncDeviceTokenToBackend(fcmToken));
      }

      // Bước 1 & 2: Lấy walletId và kết nối WebSocket với đúng topic /topic/wallets/{walletId}/notifications
      try {
        final wallet = await WalletRemoteDataSource().getMyWallet();
        final accessToken = await local.getAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          unawaited(RealtimeNotificationService().connect(
            walletId: wallet.walletId,
            accessToken: accessToken,
          ));
        }
      } catch (_) {}

      // Xin cấp quyền hệ thống (Camera, Thông báo) sau khi người dùng đã đăng nhập thành công
      unawaited(PermissionService().requestAllAppPermissions());

      AppSession.unlocked = true;
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Đăng nhập không thành công',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin({bool autoTrigger = false, int retryCount = 0}) async {
    if (_isLoading) return;
    if (!autoTrigger) HapticFeedback.selectionClick();
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        if (!autoTrigger && mounted) {
          AppAlerts.showWarning(
            context,
            'Thiết bị chưa cài đặt hoặc không hỗ trợ sinh trắc học FaceID / TouchID.',
            title: 'Sinh trắc học',
          );
        }
        return;
      }

      const storage = AppSecureStorage.instance;
      final savedPhone = await AppSecureStorage.safeRead(storage, key: AppConstants.keyPhoneNumber);
      String? savedPassword = await AppSecureStorage.safeRead(storage, key: 'biometric_saved_password');

      // Backup an toàn từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefPhone = prefs.getString('bio_saved_phone');
      final prefPwdEncoded = prefs.getString('bio_saved_pwd');
      if ((savedPassword == null || savedPassword.isEmpty) && prefPwdEncoded != null && prefPwdEncoded.isNotEmpty) {
        try {
          savedPassword = utf8.decode(base64Decode(prefPwdEncoded));
        } catch (_) {}
      }

      // Nếu trong storage chưa có mật khẩu lưu, nhưng người dùng đã nhập mật khẩu vào ô input
      if ((savedPassword == null || savedPassword.isEmpty) && _passwordController.text.isNotEmpty) {
        savedPassword = _passwordController.text;
      }

      final phone = (savedPhone != null && savedPhone.isNotEmpty) ? savedPhone : (prefPhone ?? _phoneController.text.trim());

      final existingToken = await AppSecureStorage.safeRead(storage, key: AppConstants.keyAccessToken);
      final hasToken = existingToken != null && existingToken.isNotEmpty;

      if (!hasToken && (phone.isEmpty || savedPassword == null || savedPassword.isEmpty)) {
        if (!autoTrigger && mounted) {
          AppAlerts.showInfo(
            context,
            'Vui lòng nhập Mật khẩu một lần để kích hoạt và liên kết FaceID.',
            title: 'Kích hoạt FaceID',
          );
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực FaceID để mở khóa ví Sen Hồng Bank',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        if (hasToken) {
          // Phiên còn hạn: FaceID khớp là mở khóa luôn, không cần mật khẩu
          AppSession.unlocked = true;
          context.go('/');
          return;
        }
        _phoneController.text = phone;
        _passwordController.text = savedPassword ?? '';
        await _login();
      }
    } catch (e) {
      debugPrint('[LoginScreen] Lỗi FaceID (autoTrigger: $autoTrigger, retry: $retryCount): $e');
      if (autoTrigger && retryCount == 0 && mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_isLoading) {
            _handleBiometricLogin(autoTrigger: true, retryCount: 1);
          }
        });
        return;
      }
      if (!autoTrigger && mounted) {
        AppAlerts.showError(
          context,
          'Xác thực FaceID không thành công: $e',
          title: 'Xác thực sinh trắc học',
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchAccount() {
    setState(() {
      _isMaskedUser = false;
      _accountName = '';
      _phoneController.clear();
      _passwordController.clear();
    });
  }

  void _cycleWallpaper() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đổi hình nền nghệ thuật phong cách Sen Hồng!'),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.textPrimaryLight),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Đổi hình nền app',
            icon: const Icon(CupertinoIcons.paintbrush_fill, color: AppColors.primary),
            onPressed: _cycleWallpaper,
          ),
          IconButton(
            tooltip: 'Tổng đài hỗ trợ CSKH',
            icon: const Icon(CupertinoIcons.phone_circle_fill, color: AppColors.primary),
            onPressed: () => context.push('/support/help-center'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bottomBarCyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bottomBarGlow.withOpacity(0.30),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipOval(
                    child: Image.asset('assets/icons/senbank_logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('SENBANK', style: AppTypography.displaySmall(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
              Center(
                child: Text('Ngân Hàng Số & Ví Điện Tử Tài Chính', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
              ),
              const SizedBox(height: 20),

              // Banner thông báo yêu cầu đăng nhập khi hết hạn JWT
              if (_showExpiredBanner)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warningBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warningText.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: AppColors.warningText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Yêu Cầu Đăng Nhập Lại',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.expiredMessage ??
                                  'Phiên làm việc bảo mật (JWT) đã hết hạn. Quý khách vui lòng đăng nhập lại để tiếp tục sử dụng dịch vụ.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textPrimaryLight,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showExpiredBanner = false),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: AppColors.textSecondaryLight,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Remembered User Greeting Card
              if (_isMaskedUser)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: const Icon(CupertinoIcons.person_fill, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${_accountName.isNotEmpty ? _accountName : 'Quý khách'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.primaryDark),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tài khoản Sen Hồng Bank',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _switchAccount,
                        child: const Text('Đổi tài khoản', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),

              Text('Đăng nhập', style: AppTypography.displayMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _isMaskedUser
                    ? 'Vui lòng nhập mật khẩu để tiếp tục sử dụng'
                    : 'Chào mừng bạn quay trở lại với Sen Hồng',
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 18),

              // Anti-phishing fraud alert banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.accentGold, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CẢNH BÁO: Không đăng nhập qua đường link lạ. Ngân hàng KHÔNG BAO GIỜ gọi điện yêu cầu OTP/mật khẩu.',
                        style: TextStyle(color: AppColors.warningText, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Phone Field - Chỉ hiển thị khi chưa có tài khoản ghi nhớ hoặc người dùng muốn đổi tài khoản
              if (!_isMaskedUser) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                    prefixIcon: const Icon(CupertinoIcons.phone_fill, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Password Field
              TextField(
                controller: _passwordController,
                autofocus: _isMaskedUser,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(CupertinoIcons.lock_fill, color: AppColors.primary),
                  suffixIcon: MorphEyeButton(
                    isHidden: _obscurePassword,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),

              // Remember Me Checkbox & Forgot actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isMaskedUser)
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _rememberMe = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Ghi nhớ tài khoản', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/auth/forgot-pin'),
                        child: const Text('Quên PIN', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMutedLight)),
                      TextButton(
                        onPressed: () => context.push('/auth/forgot-password'),
                        child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 16),

              // Biometric Option
              Center(
                child: InkWell(
                  onTap: _handleBiometricLogin,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.viewfinder,
                            color: AppColors.primaryDark,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasSavedBiometric ? 'Đăng nhập nhanh bằng FaceID' : 'Đăng nhập bằng FaceID / Vân tay',
                          style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Register CTA Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có tài khoản ví?', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
                  TextButton(
                    onPressed: () => context.push('/auth/register'),
                    child: const Text('Đăng ký ngay', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Chưa kích hoạt mã PIN? Thiết lập PIN',
                        onTap: () => context.push('/auth/set-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.number_circle_fill,
                        label: 'Xác thực mã OTP đăng nhập / kích hoạt',
                        onTap: () => context.push('/auth/otp'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Điều khoản dịch vụ & Chính sách bảo mật',
                        onTap: () => context.push('/auth/terms'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Trung tâm trợ giúp & CSKH 24/7 (1900 6868)',
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
