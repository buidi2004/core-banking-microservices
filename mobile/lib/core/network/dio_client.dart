import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'idempotency_interceptor.dart';

/// Tầng mạng dùng chung cho toàn bộ mobile (MOB-011 / MOB-016 / MOB-021).
///
/// - **MOB-016:** một singleton `Dio` cho cả app — 1 interceptor chain + 1
///   connection pool, thay cho việc tạo 19 instance riêng biệt như trước.
/// - **MOB-011:** logger chỉ được thêm khi chưa ở release mode, KHÔNG log header
///   hay body (có thể chứa token, PIN, PII). `requestHeader: false`.
/// - **MOB-021:** có `sendTimeout` để fail-fast thay vì treo tới 15s.
/// - KHÔNG tự động retry POST (tránh double debit).
class DioClient {
  DioClient._internal();

  /// Singleton instance dùng chung cho toàn app.
  static final DioClient instance = DioClient._internal();

  /// Giữ factory cũ để tương thích toàn bộ call-site hiện có.
  factory DioClient({String? baseUrl}) => instance;

  static Dio? _sharedDio;
  static String _activeWsUrl = ApiConstants.wsUrl;

  static const String _prefKeyApiUrl = 'custom_gateway_api_url';
  static const String _prefKeyWsUrl = 'custom_gateway_ws_url';

  /// `Dio` dùng chung — mọi datasource phải dùng getter này.
  Dio get dio => sharedDio;

  /// Trả về `Dio` singleton, chỉ tạo một lần cho toàn app.
  static Dio get sharedDio {
    return _sharedDio ??= _buildDio();
  }

  /// Địa chỉ WebSocket STOMP hiện hành (hỗ trợ cả ws:// local và wss:// Codespaces).
  static String get activeWsUrl => _activeWsUrl;

  /// Chuẩn hóa đường dẫn API Gateway (tự động thêm https:// và /api/v1 nếu người dùng chỉ dán domain Codespaces).
  static String normalizeApiUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return ApiConstants.baseUrl;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.app.github.dev') ||
          url.contains('.github.dev') ||
          url.contains('.ngrok') ||
          url.contains('.trycloudflare.com')) {
        url = 'https://$url';
      } else {
        url = 'http://$url';
      }
    }

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    if (!url.endsWith('/api/v1')) {
      url = '$url/api/v1';
    }
    return url;
  }

  /// Tự động suy diễn địa chỉ WebSocket (/ws-native) từ địa chỉ API Gateway.
  static String deriveWsUrl(String apiUrl, {String? customWsUrl}) {
    if (customWsUrl != null && customWsUrl.trim().isNotEmpty) {
      var ws = customWsUrl.trim();
      while (ws.endsWith('/')) {
        ws = ws.substring(0, ws.length - 1);
      }
      if (!ws.endsWith('/ws-native') && !ws.endsWith('/ws')) {
        ws = '$ws/ws-native';
      }
      return ws;
    }

    final normalizedApi = normalizeApiUrl(apiUrl);
    final baseHost = normalizedApi.replaceFirst(RegExp(r'/api/v1$'), '');
    if (baseHost.startsWith('https://')) {
      return 'wss://${baseHost.substring('https://'.length)}/ws-native';
    } else if (baseHost.startsWith('http://')) {
      return 'ws://${baseHost.substring('http://'.length)}/ws-native';
    }
    return ApiConstants.wsUrl;
  }

  /// Nạp cấu hình Gateway đã lưu trong SharedPreferences (nếu có) khi mở ứng dụng.
  static Future<void> initSavedGateway() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApi = prefs.getString(_prefKeyApiUrl);
      final savedWs = prefs.getString(_prefKeyWsUrl);
      if (savedApi != null && savedApi.trim().isNotEmpty) {
        final normApi = normalizeApiUrl(savedApi);
        sharedDio.options.baseUrl = normApi;
        _activeWsUrl = deriveWsUrl(normApi, customWsUrl: savedWs);
      } else {
        _activeWsUrl = deriveWsUrl(sharedDio.options.baseUrl);
      }
    } catch (_) {}
  }

  /// Cho phép đổi động địa chỉ Gateway (VD: chuyển sang link GitHub Codespaces lúc runtime) và lưu bền vững.
  static Future<void> updateBaseUrl(String newBaseUrl, {String? newWsUrl}) async {
    final normalizedApi = normalizeApiUrl(newBaseUrl);
    final derivedWs = deriveWsUrl(normalizedApi, customWsUrl: newWsUrl);
    sharedDio.options.baseUrl = normalizedApi;
    _activeWsUrl = derivedWs;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyApiUrl, normalizedApi);
      await prefs.setString(_prefKeyWsUrl, derivedWs);
    } catch (_) {}
  }

  static Dio _buildDio() {
    final initialApi = normalizeApiUrl(ApiConstants.baseUrl);
    _activeWsUrl = deriveWsUrl(initialApi, customWsUrl: ApiConstants.wsUrl);
    final dio = Dio(
      BaseOptions(
        baseUrl: initialApi,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15), // MOB-021
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      IdempotencyInterceptor(),
      // MOB-011: chỉ log ở debug/profile; không log header/body ở bất kỳ chế độ nào.
      if (!kReleaseMode)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);

    return dio;
  }
}
