import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/network/auth_interceptor.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ResponseBody rawStringResponse(String body, {int statusCode = 200, String contentType = 'text/html'}) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [contentType],
    },
  );
}

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.from(_data);
}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  String? accessToken;
  String? refreshToken;
  String? userId;
  String? phoneNumber;
  String? fullName;
  String? walletId;
  bool hideBalance = false;

  final List<String> operationLog = [];

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    operationLog.add('saveTokens');
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async {
    operationLog.add('getAccessToken');
    return accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    operationLog.add('getRefreshToken');
    return refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    operationLog.add('clearTokens');
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<void> saveIdentity({required String userId, required String phoneNumber}) async {
    this.userId = userId;
    this.phoneNumber = phoneNumber;
  }

  @override
  Future<void> saveFullName(String fullName) async {
    this.fullName = fullName;
  }

  @override
  Future<String?> getFullName() async => fullName;

  @override
  Future<void> saveWalletId(String walletId) async {
    this.walletId = walletId;
  }

  @override
  Future<String?> getWalletId() async => walletId;

  @override
  Future<void> setHideBalance(bool hide) async => hideBalance = hide;

  @override
  Future<bool> getHideBalance() async => hideBalance;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFlutterSecureStorage secureStorage;
  late FakeAuthLocalDataSource localAuth;

  setUp(() {
    secureStorage = FakeFlutterSecureStorage();
    localAuth = FakeAuthLocalDataSource();
  });

  group('CHALLENGER STRESS TESTS: W1 & W2 Authenticity & Resilience', () {
    // -----------------------------------------------------------------------
    // Stress Test 1: Real Backend AuthResponse envelope parsing
    // -----------------------------------------------------------------------
    test('Stress 1: AuthInterceptor unwraps authentic backend AuthResponse envelope', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'expired-access-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'valid-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-stress-1',
        clientAdapter: adapter,
      );
      dio.interceptors.add(authInterceptor);

      int userMeAttempts = 0;
      RequestOptions? refreshRequest;

      adapter.handler = (options) {
        if (options.path.endsWith('/users/me')) {
          userMeAttempts++;
          if (userMeAttempts == 1) {
            return jsonResponse({
              'success': false,
              'message': 'Token has expired',
              'errorCode': 'TOKEN_EXPIRED',
            }, statusCode: 401);
          }
          return jsonResponse({
            'success': true,
            'data': {'id': 'usr-real-1', 'fullName': 'Tran Real'},
          });
        }

        if (options.path.contains(ApiConstants.refresh)) {
          refreshRequest = options;
          // Actual backend structure: data contains token, refreshToken, tokenType, expiresIn
          return jsonResponse({
            'success': true,
            'message': 'Làm mới token thành công',
            'data': {
              'token': 'real-backend-jwt-access-token',
              'refreshToken': 'real-backend-jwt-refresh-token',
              'tokenType': 'Bearer',
              'expiresIn': 86400,
              'userId': 'usr-real-1',
              'username': '0987654321',
            },
          });
        }

        return jsonResponse({'success': true});
      };

      final response = await dio.get('/users/me');
      expect(response.statusCode, 200);
      expect(userMeAttempts, 2);

      expect(refreshRequest, isNotNull);
      expect(refreshRequest!.method, 'POST');
      expect(refreshRequest!.data['refreshToken'], 'valid-refresh-token');
      expect(refreshRequest!.data['deviceId'], 'device-stress-1');

      // Verify tokens stored
      expect(await secureStorage.read(key: AppConstants.keyAccessToken), 'real-backend-jwt-access-token');
      expect(await secureStorage.read(key: AppConstants.keyRefreshToken), 'real-backend-jwt-refresh-token');
    });

    // -----------------------------------------------------------------------
    // Stress Test 2: Error Propagation when Refresh returns 401
    // -----------------------------------------------------------------------
    test('Stress 2: Refresh returns 401 -> clears storage, rejects with clean session expired exception, no loop', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'expired-access-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'expired-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-stress-2',
        clientAdapter: adapter,
      );
      dio.interceptors.add(authInterceptor);

      int refreshCalls = 0;
      adapter.handler = (options) {
        if (options.path.endsWith('/users/me')) {
          return jsonResponse({
            'success': false,
            'message': 'Access token expired',
          }, statusCode: 401);
        }

        if (options.path.contains(ApiConstants.refresh)) {
          refreshCalls++;
          return jsonResponse({
            'success': false,
            'message': 'Refresh token expired or revoked',
            'errorCode': 'REFRESH_TOKEN_EXPIRED',
          }, statusCode: 401);
        }

        return jsonResponse({'success': true});
      };

      DioException? capturedException;
      try {
        await dio.get('/users/me');
      } on DioException catch (e) {
        capturedException = e;
      }

      expect(capturedException, isNotNull);
      expect(refreshCalls, 1); // Refresh called exactly once, no recursive loop
      expect(capturedException!.message, contains('Phiên đăng nhập đã hết hạn'));

      // Tokens MUST be cleared
      expect(await secureStorage.read(key: AppConstants.keyAccessToken), isNull);
      expect(await secureStorage.read(key: AppConstants.keyRefreshToken), isNull);
    });

    // -----------------------------------------------------------------------
    // Stress Test 3: Error Propagation on Network Error during Refresh
    // -----------------------------------------------------------------------
    test('Stress 3: Network error on refresh -> clears storage, rejects without unhandled crash', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'expired-access-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'some-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-stress-3',
        clientAdapter: adapter,
      );
      dio.interceptors.add(authInterceptor);

      adapter.handler = (options) {
        if (options.path.endsWith('/users/me')) {
          return jsonResponse({'success': false}, statusCode: 401);
        }

        if (options.path.contains(ApiConstants.refresh)) {
          // Simulate connection timeout
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timed out',
          );
        }

        return jsonResponse({'success': true});
      };

      DioException? capturedException;
      try {
        await dio.get('/users/me');
      } on DioException catch (e) {
        capturedException = e;
      }

      expect(capturedException, isNotNull);
      expect(await secureStorage.read(key: AppConstants.keyAccessToken), isNull);
      expect(await secureStorage.read(key: AppConstants.keyRefreshToken), isNull);
    });

    // -----------------------------------------------------------------------
    // Stress Test 4: Malformed response on Refresh (e.g. 502 Bad Gateway HTML)
    // -----------------------------------------------------------------------
    test('Stress 4: 502 Bad Gateway HTML on refresh -> gracefully fails and clears storage', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'expired-access-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'some-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-stress-4',
        clientAdapter: adapter,
      );
      dio.interceptors.add(authInterceptor);

      adapter.handler = (options) {
        if (options.path.endsWith('/users/me')) {
          return jsonResponse({'success': false}, statusCode: 401);
        }

        if (options.path.contains(ApiConstants.refresh)) {
          return rawStringResponse('<html><body>502 Bad Gateway</body></html>', statusCode: 502);
        }

        return jsonResponse({'success': true});
      };

      DioException? capturedException;
      try {
        await dio.get('/users/me');
      } on DioException catch (e) {
        capturedException = e;
      }

      expect(capturedException, isNotNull);
      expect(await secureStorage.read(key: AppConstants.keyAccessToken), isNull);
    });

    // -----------------------------------------------------------------------
    // Stress Test 5: Concurrent 401 requests deduplicated to 1 refresh call
    // -----------------------------------------------------------------------
    test('Stress 5: 10 concurrent 401 requests trigger only 1 refresh call and all 10 retry', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'expired-access-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'valid-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-stress-5',
        clientAdapter: adapter,
      );
      dio.interceptors.add(authInterceptor);

      int refreshCallCount = 0;
      final retriedCalls = <String>[];

      adapter.handler = (options) {
        if (options.path.contains(ApiConstants.refresh)) {
          refreshCallCount++;
          return jsonResponse({
            'success': true,
            'data': {
              'token': 'renewed-access-token',
              'refreshToken': 'renewed-refresh-token',
            },
          });
        }

        final authHeader = options.headers['Authorization'] as String?;
        if (authHeader == 'Bearer renewed-access-token') {
          retriedCalls.add(options.path);
          return jsonResponse({'success': true, 'path': options.path});
        }

        // Initially with expired token -> return 401
        return jsonResponse({'success': false, 'message': 'Token expired'}, statusCode: 401);
      };

      final futures = List.generate(10, (index) => dio.get('/data/endpoint_$index'));
      final responses = await Future.wait(futures);

      expect(responses.length, 10);
      for (final r in responses) {
        expect(r.statusCode, 200);
      }
      expect(refreshCallCount, 1, reason: 'Must deduplicate concurrent refresh requests to exactly 1');
      expect(retriedCalls.length, 10, reason: 'All 10 requests must retry with renewed token');
    });

    // -----------------------------------------------------------------------
    // Stress Test 6: Business 401s do NOT trigger refresh or clear tokens
    // -----------------------------------------------------------------------
    test('Stress 6: Business 401 on login or with INVALID_PIN does NOT clear tokens or trigger refresh', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'active-valid-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'active-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-stress-6',
        clientAdapter: adapter,
      );
      dio.interceptors.add(authInterceptor);

      int refreshCount = 0;
      adapter.handler = (options) {
        if (options.path.contains(ApiConstants.refresh)) {
          refreshCount++;
          return jsonResponse({'success': true});
        }

        if (options.path.contains('/payments/transfer/confirm')) {
          return jsonResponse({
            'success': false,
            'errorCode': 'INVALID_PIN',
            'message': 'Mã PIN không chính xác',
          }, statusCode: 401);
        }

        return jsonResponse({'success': true});
      };

      DioException? capturedException;
      try {
        await dio.post('/payments/transfer/confirm', data: {'pin': '000000'});
      } on DioException catch (e) {
        capturedException = e;
      }

      expect(capturedException, isNotNull);
      expect(refreshCount, 0, reason: 'Must not trigger token refresh for business 401');
      // Tokens must REMAIN intact
      expect(await secureStorage.read(key: AppConstants.keyAccessToken), 'active-valid-token');
      expect(await secureStorage.read(key: AppConstants.keyRefreshToken), 'active-refresh-token');
    });

    // -----------------------------------------------------------------------
    // Stress Test 7: W2 Logout order and resilience under network failure
    // -----------------------------------------------------------------------
    test('Stress 7: Logout sends token header and deviceId; clears local even if backend fails', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await localAuth.saveTokens(
        accessToken: 'user-token-for-logout',
        refreshToken: 'refresh-token-for-logout',
      );
      localAuth.operationLog.clear();

      final capturedRequests = <RequestOptions>[];
      adapter.handler = (options) {
        capturedRequests.add(options);
        if (options.path.contains(ApiConstants.logout)) {
          // Backend returns 500 Internal Server Error
          return jsonResponse({'success': false, 'message': 'Internal Server Error'}, statusCode: 500);
        }
        return jsonResponse({'success': true});
      };

      final authRemote = AuthRemoteDataSource(dio: dio, local: localAuth);
      await authRemote.logout(deviceId: 'dev-999');

      final logoutReq = capturedRequests.firstWhere((r) => r.path.contains(ApiConstants.logout));
      expect(logoutReq.method, 'POST');
      expect(logoutReq.headers['Authorization'], 'Bearer user-token-for-logout');
      expect(logoutReq.queryParameters['deviceId'], 'dev-999');

      // Crucial verification: clearTokens MUST be called even on 500 error
      expect(localAuth.operationLog.contains('clearTokens'), isTrue);
      expect(await localAuth.getAccessToken(), isNull);
      expect(await localAuth.getRefreshToken(), isNull);
    });
  });
}
