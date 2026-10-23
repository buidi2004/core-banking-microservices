import 'dart:convert';
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

  /// Địa chỉ file cấu hình Cloud Endpoint tự động đồng bộ từ GitHub Codespaces (Phương án 2).
  static const String cloudEndpointRegistryUrl =
      'https://raw.githubusercontent.com/buidi2004/core-banking-microservices/main/cloud-endpoint.json';

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

  /// Hoán đổi tự động giữa cổng trực tiếp Gateway (-8080) và cổng Proxy Vite (-5173) trên GitHub Codespaces.
  static String? siblingCodespaceApiUrl(String apiUrl) {
    final normalized = normalizeApiUrl(apiUrl);
    if (normalized.contains('-8080.app.github.dev')) {
      return normalized.replaceAll('-8080.app.github.dev', '-5173.app.github.dev');
    }
    if (normalized.contains('-5173.app.github.dev')) {
      return normalized.replaceAll('-5173.app.github.dev', '-8080.app.github.dev');
    }
    return null;
  }

  /// Kiểm tra xem phản hồi có bị GitHub Codespaces chặn (chuyển hướng sang trang HTML pf-signin do cổng Private) hay không.
  static bool isHtmlOrTunnelRedirect(Response<dynamic>? response) {
    if (response == null) return false;
    final realHost = response.realUri.host.toLowerCase();
    final realPath = response.realUri.path.toLowerCase();
    if (realHost.contains('github.com') ||
        realPath.contains('pf-signin') ||
        realPath.contains('/login/oauth')) {
      return true;
    }
    final contentType = (response.headers.value('content-type') ?? '').toLowerCase();
    if (contentType.contains('text/html')) {
      return true;
    }
    if (response.data is String) {
      final body = (response.data as String).trimLeft();
      if (body.startsWith('<!DOCTYPE') ||
          body.startsWith('<!doctype') ||
          body.startsWith('<html') ||
          body.startsWith('<head') ||
          body.contains('pf-signin')) {
        return true;
      }
    }
    return false;
  }

  /// Kiểm tra nhanh 1 địa chỉ API Gateway xem có phản hồi JSON thực từ Backend hay không.
  static Future<bool> probeGatewayReachable(String candidateApiUrl) async {
    try {
      final norm = normalizeApiUrl(candidateApiUrl);
      final probe = Dio(
        BaseOptions(
          baseUrl: norm,
          connectTimeout: const Duration(milliseconds: 3500),
          receiveTimeout: const Duration(milliseconds: 3500),
          validateStatus: (status) => status != null && status < 500,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'X-Tunnel-Skip-AntiPhishing-Page': 'true',
          },
        ),
      );
      final res = await probe.post('/auth/login', data: const {});
      if (isHtmlOrTunnelRedirect(res)) return false;
      return res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }

  /// Nạp cấu hình Gateway đã lưu trong SharedPreferences (nếu có) và tự động đồng bộ từ GitHub Cloud Registry.
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

      // Phương án 2: Tự động kéo link Codespace mới nhất từ GitHub Repo (không cần copy-paste khi cài APK)
      final currentBase = sharedDio.options.baseUrl;
      if (currentBase.contains('localhost') ||
          currentBase.contains('10.0.2.2') ||
          currentBase.contains('.app.github.dev')) {
        await syncFromCloudRegistry();
      }
    } catch (_) {}
  }

  /// Tự động đọc file `cloud-endpoint.json` trên GitHub để cập nhật URL Codespace đang bật
  /// và tự động chọn cổng tốt nhất (-8080 trực tiếp hoặc -5173 qua Vite Proxy).
  static Future<String?> syncFromCloudRegistry() async {
    try {
      final probe = Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 3000),
          receiveTimeout: const Duration(milliseconds: 3000),
          responseType: ResponseType.plain,
        ),
      );
      final res = await probe.get(
        '$cloudEndpointRegistryUrl?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      if (res.statusCode == 200 && res.data != null) {
        final decoded = jsonDecode(res.data.toString());
        if (decoded is Map<String, dynamic>) {
          final remoteApi = (decoded['apiUrl'] ?? decoded['gatewayUrl'] ?? '')
              .toString()
              .trim();
          final remotePortal = (decoded['portalUrl'] ?? '').toString().trim();
          final remoteWs = (decoded['wsUrl'] ?? '').toString().trim();

          if (remoteApi.isNotEmpty && remoteApi.startsWith('https://')) {
            final primaryApi = normalizeApiUrl(remoteApi);
            if (await probeGatewayReachable(primaryApi)) {
              await updateBaseUrl(
                primaryApi,
                newWsUrl: remoteWs.isNotEmpty ? remoteWs : null,
              );
              return sharedDio.options.baseUrl;
            }

            // Tự động failover sang cổng 5173 (Vite Proxy) nếu cổng 8080 đang Private hoặc đang restart
            final fallbackApi = remotePortal.isNotEmpty
                ? normalizeApiUrl(remotePortal)
                : siblingCodespaceApiUrl(primaryApi);
            if (fallbackApi != null && await probeGatewayReachable(fallbackApi)) {
              await updateBaseUrl(fallbackApi);
              return sharedDio.options.baseUrl;
            }

            // Nếu đang ngoại tuyến hoặc cả 2 chưa phản hồi, vẫn lưu primaryApi mới nhất từ GitHub
            await updateBaseUrl(
              primaryApi,
              newWsUrl: remoteWs.isNotEmpty ? remoteWs : null,
            );
            return sharedDio.options.baseUrl;
          }
        }
      }
    } catch (_) {}

    // Ngay cả khi không tải được cloud-endpoint.json, kiểm tra cổng hiện tại và failover sang cổng anh em nếu cần
    final current = sharedDio.options.baseUrl;
    if (current.contains('.app.github.dev')) {
      if (!await probeGatewayReachable(current)) {
        final sibling = siblingCodespaceApiUrl(current);
        if (sibling != null && await probeGatewayReachable(sibling)) {
          await updateBaseUrl(sibling);
          return sharedDio.options.baseUrl;
        }
      }
    }
    return null;
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
          'X-Tunnel-Skip-AntiPhishing-Page': 'true',
        },
      ),
    );

    dio.interceptors.addAll([
      _CodespacesFailoverInterceptor(),
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

/// Interceptor bảo vệ kết nối GitHub Codespaces:
/// 1. Tự động giải mã JSON nếu proxy trả về String JSON.
/// 2. Phát hiện khi cổng Codespaces bị chuyển về Private (redirect sang trang HTML pf-signin)
///    hoặc lỗi 502/503/504 và tự động failover tức thì giữa cổng -8080 và -5173 (Vite Proxy).
class _CodespacesFailoverInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.data is String) {
      final raw = (response.data as String).trim();
      if (raw.startsWith('{') || raw.startsWith('[')) {
        try {
          response.data = jsonDecode(raw);
          return handler.next(response);
        } catch (_) {}
      }
    }

    if (DioClient.isHtmlOrTunnelRedirect(response)) {
      final req = response.requestOptions;
      if (req.extra['codespace_failover_retried'] != true) {
        final siblingBase = DioClient.siblingCodespaceApiUrl(req.baseUrl);
        if (siblingBase != null) {
          final fallbackRes = await _trySiblingRequest(req, siblingBase);
          if (fallbackRes != null && !DioClient.isHtmlOrTunnelRedirect(fallbackRes)) {
            await DioClient.updateBaseUrl(siblingBase);
            return handler.resolve(fallbackRes);
          }
        }
      }
      const msg =
          'Cổng GitHub Codespaces đang ở chế độ Private hoặc đang khởi động lại. Vui lòng mở tab Cổng (Ports) trên Codespaces và đặt cổng 8080 / 5173 thành Public.';
      return handler.reject(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 503,
            data: {'success': false, 'message': msg, 'errorCode': 'CODESPACE_PORT_PRIVATE'},
          ),
          type: DioExceptionType.badResponse,
          error: Exception(msg),
          message: msg,
        ),
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final status = err.response?.statusCode;
    final isTunnelOrGatewayFailure = err.response == null ||
        (status != null && status >= 500) ||
        DioClient.isHtmlOrTunnelRedirect(err.response);

    if (isTunnelOrGatewayFailure &&
        req.extra['codespace_failover_retried'] != true &&
        req.baseUrl.contains('.app.github.dev')) {
      final siblingBase = DioClient.siblingCodespaceApiUrl(req.baseUrl);
      if (siblingBase != null) {
        final fallbackRes = await _trySiblingRequest(req, siblingBase);
        if (fallbackRes != null && !DioClient.isHtmlOrTunnelRedirect(fallbackRes)) {
          await DioClient.updateBaseUrl(siblingBase);
          if (fallbackRes.statusCode != null &&
              fallbackRes.statusCode! >= 200 &&
              fallbackRes.statusCode! < 300) {
            return handler.resolve(fallbackRes);
          } else {
            return handler.next(
              DioException(
                requestOptions: req..baseUrl = siblingBase,
                response: fallbackRes,
                type: DioExceptionType.badResponse,
              ),
            );
          }
        }
      }
    }

    handler.next(err);
  }

  Future<Response<dynamic>?> _trySiblingRequest(
    RequestOptions original,
    String siblingBaseUrl,
  ) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: siblingBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final headers = Map<String, dynamic>.from(original.headers);
      headers['X-Requested-With'] = 'XMLHttpRequest';
      headers['X-Tunnel-Skip-AntiPhishing-Page'] = 'true';

      final res = await dio.request<dynamic>(
        original.path,
        data: original.data,
        queryParameters: original.queryParameters,
        options: Options(
          method: original.method,
          headers: headers,
          contentType: original.contentType,
          responseType: original.responseType,
          extra: {
            ...original.extra,
            'codespace_failover_retried': true,
          },
        ),
      );
      if (res.data is String) {
        final raw = (res.data as String).trim();
        if (raw.startsWith('{') || raw.startsWith('[')) {
          try {
            res.data = jsonDecode(raw);
          } catch (_) {}
        }
      }
      return res;
    } catch (_) {
      return null;
    }
  }
}
