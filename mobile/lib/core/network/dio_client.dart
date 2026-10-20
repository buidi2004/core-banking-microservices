import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
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

  /// `Dio` dùng chung — mọi datasource phải dùng getter này.
  Dio get dio => sharedDio;

  /// Trả về `Dio` singleton, chỉ tạo một lần cho toàn app.
  static Dio get sharedDio {
    return _sharedDio ??= _buildDio();
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15), // MOB-021
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
