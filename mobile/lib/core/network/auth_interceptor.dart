import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../storage/app_secure_storage.dart';
import '../theme/app_colors.dart';
import '../../presentation/routes/app_router.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  /// Completer dùng làm khóa (lock/mutex) để đồng bộ hóa việc làm mới token.
  /// Khi nhiều request nhận 401 cùng lúc, chỉ 1 request thực sự gọi BE /auth/refresh,
  /// các request khác đợi completer hoàn thành và dùng token mới để retry.
  static Completer<String?>? _refreshCompleter;

  AuthInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? AppSecureStorage.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final path = options.path;
      final isAuthEndpoint = path.contains(ApiConstants.login) ||
          path.contains(ApiConstants.register);

      if (!isAuthEndpoint) {
        final token = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAccessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      debugPrint('[AuthInterceptor] Bỏ qua lỗi đọc token an toàn: $e');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final path = request.path;

    // 1. Kiểm tra xem 401 này có phải là lỗi nghiệp vụ (Business 401) hay không:
    // Ví dụ: sai mật khẩu login, sai PIN chuyển tiền, chưa tạo PIN...
    // Các lỗi này KHÔNG PHẢI là hết hạn JWT, tuyệt đối không xóa token hay thử refresh!
    final isBusinessEndpoint = path.contains(ApiConstants.login) ||
        path.contains(ApiConstants.register) ||
        path.contains('/confirm') ||
        path.contains('/pin') ||
        path.contains('/otp');

    String? errorCode;
    String? serverMessage;
    if (err.response?.data is Map) {
      final map = err.response!.data as Map;
      errorCode = map['errorCode']?.toString();
      serverMessage = map['message']?.toString();
    } else if (err.response?.data is String) {
      serverMessage = err.response!.data as String;
    }

    final isBusinessAuthError = isBusinessEndpoint ||
        errorCode == 'INVALID_PIN' ||
        errorCode == 'INVALID_CREDENTIALS' ||
        errorCode == 'PIN_NOT_SET';

    // --- Xử lý 401: Chỉ refresh khi đây là lỗi JWT Access Token hết hạn ---
    if (statusCode == 401 &&
        !isBusinessAuthError &&
        path != ApiConstants.refresh &&
        request.extra['retried'] != true) {

      try {
        final newAccessToken = await _performTokenRefresh(request.baseUrl);
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Retry request ban đầu với accessToken mới
          request.headers['Authorization'] = 'Bearer $newAccessToken';
          request.extra['retried'] = true;
          final retryDio = Dio(BaseOptions(baseUrl: request.baseUrl));
          final retryResponse = await retryDio.fetch(request);
          return handler.resolve(retryResponse);
        } else {
          await _clearTokensAndRedirect();
          return handler.reject(_cleanSessionExpiredException(request, err.response));
        }
      } catch (_) {
        await _clearTokensAndRedirect();
        return handler.reject(_cleanSessionExpiredException(request, err.response));
      }
    }

    // --- Xử lý 403: Forbidden từ Spring Security ---
    if (statusCode == 403 && request.extra['retried'] != true) {
      final token = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAccessToken);
      if (token == null || token.isEmpty) {
        await _clearTokensAndRedirect();
        return handler.reject(_cleanSessionExpiredException(request, err.response));
      }
    }

    // Làm sạch message nếu có serverMessage từ BE để UI hiển thị đẹp
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return handler.reject(
        DioException(
          requestOptions: request,
          response: err.response,
          type: err.type,
          error: Exception(serverMessage),
          message: serverMessage,
        ),
      );
    }

    handler.next(err);
  }

  /// Đồng bộ việc refresh token, tránh race condition khi nhiều request 401 cùng lúc
  Future<String?> _performTokenRefresh(String baseUrl) async {
    // Nếu đang có 1 tiến trình refresh chạy, chỉ cần đợi nó xong
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter?.complete(null);
        return null;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await refreshDio.post(
        ApiConstants.refresh,
        queryParameters: {'refreshToken': refreshToken},
      );

      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyAccessToken, value: newAccessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyRefreshToken, value: newRefreshToken);
        }
        _refreshCompleter?.complete(newAccessToken);
        return newAccessToken;
      } else {
        _refreshCompleter?.complete(null);
        return null;
      }
    } catch (e) {
      _refreshCompleter?.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Thời điểm khởi chạy ứng dụng để xác định giai đoạn khởi động êm dịu (Cold Start Grace Period)
  static final DateTime _appStartTime = DateTime.now();

  /// Biến cờ ngăn việc mở trùng lặp nhiều dialog khi nhiều API đồng thời báo hết hạn JWT
  static bool _isSessionExpiredDialogShowing = false;

  /// Xóa toàn bộ token và chỉ hiển thị hộp thoại nếu người dùng đang chủ động dùng app (không phải lúc mở/load app)
  Future<void> _clearTokensAndRedirect() async {
    final hadToken = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAccessToken);
    await AppSecureStorage.safeDelete(_storage, key: AppConstants.keyAccessToken);
    await AppSecureStorage.safeDelete(_storage, key: AppConstants.keyRefreshToken);

    // Nếu dialog đang mở thì không mở thêm
    if (_isSessionExpiredDialogShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = appRouter.routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        try {
          appRouter.go('/auth/login');
        } catch (e) {
          debugPrint('GoRouter redirect error: $e');
        }
        return;
      }

      final currentLoc = appRouter.routerDelegate.currentConfiguration.uri.toString();

      // Tuyệt đối KHÔNG hiển thị popup nếu:
      // 1. Đang ở màn hình khởi động Splash (/splash)
      // 2. Đang ở các màn hình xác thực (/auth)
      if (currentLoc == '/splash' || currentLoc.startsWith('/splash') || currentLoc.startsWith('/auth')) {
        return;
      }

      // 3. Trước đó chưa từng có token (chưa đăng nhập, không làm phiền lúc load app)
      if (hadToken == null || hadToken.isEmpty) {
        try {
          appRouter.go('/auth/login');
        } catch (_) {}
        return;
      }

      // 4. Trong giai đoạn khởi động ứng dụng (Cold Start Grace Period < 10s):
      // Điều hướng êm dịu sang màn Đăng nhập kèm cờ sessionExpired để LoginScreen hiển thị rõ thông báo yêu cầu đăng nhập
      final isColdStart = DateTime.now().difference(_appStartTime).inSeconds < 10;
      if (isColdStart) {
        try {
          appRouter.go('/auth/login?sessionExpired=true');
        } catch (_) {}
        return;
      }

      _isSessionExpiredDialogShowing = true;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Icon(
                    CupertinoIcons.lock_shield_fill,
                    color: AppColors.warningText,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Yêu Cầu Đăng Nhập',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phiên làm việc bảo mật (JWT) của Quý khách đã hết hạn. Vui lòng đăng nhập lại để bảo vệ an toàn tài khoản và tiếp tục sử dụng dịch vụ.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.warningText, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quý khách chỉ cần nhập lại Mật khẩu để tiếp tục sử dụng ngay.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.warningText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _isSessionExpiredDialogShowing = false;
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                    appRouter.go('/auth/login?sessionExpired=true');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng nhập lại ngay',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  DioException _cleanSessionExpiredException(RequestOptions request, Response? response) {
    const msg = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    return DioException(
      requestOptions: request,
      response: response,
      type: DioExceptionType.badResponse,
      error: Exception(msg),
      message: msg,
    );
  }
}
