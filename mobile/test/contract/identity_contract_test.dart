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
import 'package:sen_hong_bank/data/datasources/remote/money_request_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/notification_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/session_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

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

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clearTokens() async {
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

  late MockHttpClientAdapter adapter;
  late Dio dio;
  late FakeFlutterSecureStorage secureStorage;
  late FakeAuthLocalDataSource localAuth;

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
    dio.httpClientAdapter = adapter;
    secureStorage = FakeFlutterSecureStorage();
    localAuth = FakeAuthLocalDataSource();
  });

  group('Milestone 1 Contract Tests (W1 - W7)', () {
    // -------------------------------------------------------------
    // W1: Refresh Token Contract (MOB-001)
    // -------------------------------------------------------------
    test('W1: AuthInterceptor refresh sends JSON body and no query params, unwraps response', () async {
      final interceptorDio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      final interceptorAdapter = MockHttpClientAdapter();
      interceptorDio.httpClientAdapter = interceptorAdapter;

      await secureStorage.write(key: AppConstants.keyAccessToken, value: 'expired-access-token');
      await secureStorage.write(key: AppConstants.keyRefreshToken, value: 'valid-refresh-token');

      final authInterceptor = AuthInterceptor(
        storage: secureStorage,
        deviceId: 'device-test-123',
        clientAdapter: interceptorAdapter,
      );
      interceptorDio.interceptors.add(authInterceptor);

      final capturedRequests = <RequestOptions>[];
      int callCount = 0;

      interceptorAdapter.handler = (options) {
        capturedRequests.add(options);
        callCount++;

        if (options.path.endsWith('/users/me') && callCount == 1) {
          // Lần đầu: 401 JWT expired
          return jsonResponse({
            'success': false,
            'message': 'JWT expired',
            'errorCode': 'TOKEN_EXPIRED',
          }, statusCode: 401);
        }

        if (options.path.contains('/auth/refresh')) {
          // Refresh call
          return jsonResponse({
            'success': true,
            'data': {
              'token': {
                'accessToken': 'new-valid-access-token',
                'refreshToken': 'new-valid-refresh-token',
              },
            },
          });
        }

        if (options.path.endsWith('/users/me') && callCount == 3) {
          // Retry sau khi refresh thành công
          return jsonResponse({
            'success': true,
            'data': {
              'id': 'usr-1',
              'fullName': 'Nguyen Van A',
            },
          });
        }

        return jsonResponse({'success': true});
      };

      final response = await interceptorDio.get('/users/me');
      expect(response.statusCode, 200);

      // Tìm request /auth/refresh
      final refreshReq = capturedRequests.firstWhere(
        (req) => req.path.contains('/auth/refresh'),
        orElse: () => throw TestFailure('No refresh request observed'),
      );

      expect(refreshReq.method, 'POST');
      expect(refreshReq.queryParameters, isEmpty);
      expect(refreshReq.headers['Authorization'], isNull);

      final body = refreshReq.data as Map;
      expect(body['refreshToken'], 'valid-refresh-token');
      expect(body['deviceId'], 'device-test-123');

      // Token mới được ghi vào secureStorage
      expect(await secureStorage.read(key: AppConstants.keyAccessToken), 'new-valid-access-token');
    });

    // -------------------------------------------------------------
    // W2: Logout Contract & Local Cleanup (MOB-009)
    // -------------------------------------------------------------
    test('W2: AuthRemoteDataSource logout sends query param deviceId, token header, clears local', () async {
      await localAuth.saveTokens(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
      );

      RequestOptions? logoutOptions;
      adapter.handler = (options) {
        if (options.path.contains(ApiConstants.logout)) {
          logoutOptions = options;
          return jsonResponse({'success': true, 'message': 'Logged out'});
        }
        return jsonResponse({'success': true});
      };

      final authRemote = AuthRemoteDataSource(dio: dio, local: localAuth);
      await authRemote.logout(deviceId: 'device-test-456');

      expect(logoutOptions, isNotNull);
      expect(logoutOptions!.method, 'POST');
      expect(logoutOptions!.queryParameters['deviceId'], 'device-test-456');
      expect(logoutOptions!.headers['Authorization'], 'Bearer mock-access-token');

      // Tokens phải bị clear khỏi local storage
      expect(await localAuth.getAccessToken(), isNull);
      expect(await localAuth.getRefreshToken(), isNull);
    });

    // -------------------------------------------------------------
    // W3: Profile Update Contract (MOB-004)
    // -------------------------------------------------------------
    test('W3: ProfileRemoteDataSource updateMe sends PUT /users/profile with body, conditionally includes dateOfBirth', () async {
      final profileRemote = ProfileRemoteDataSource(dio: dio, storage: secureStorage);
      final capturedCalls = <RequestOptions>[];

      adapter.handler = (options) {
        capturedCalls.add(options);
        return jsonResponse({
          'success': true,
          'data': {
            'fullName': options.data is Map ? options.data['fullName'] : 'Updated',
            'email': options.data is Map ? options.data['email'] : 'test@example.com',
          },
        });
      };

      // Case A: có dateOfBirth
      await profileRemote.updateMe(
        fullName: 'Le Van B',
        email: 'b@example.com',
        dob: '1995-10-25',
      );

      final reqA = capturedCalls.last;
      expect(reqA.path, ApiConstants.userProfile);
      expect(reqA.method, 'PUT');
      expect(reqA.queryParameters, isEmpty);
      expect(reqA.data['fullName'], 'Le Van B');
      expect(reqA.data['email'], 'b@example.com');
      expect(reqA.data['dateOfBirth'], '1995-10-25');

      // Case B: không có dateOfBirth (chuỗi rỗng)
      await profileRemote.updateMe(
        fullName: 'Le Van B',
        email: 'b@example.com',
        dob: '',
      );

      final reqB = capturedCalls.last;
      expect(reqB.path, ApiConstants.userProfile);
      expect(reqB.method, 'PUT');
      expect(reqB.queryParameters, isEmpty);
      expect(reqB.data.containsKey('dateOfBirth'), isFalse);

      // Update avatar: xử lý offline mà không gửi request mạng
      capturedCalls.clear();
      final avatarResult = await profileRemote.updateAvatar('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...');
      expect(capturedCalls, isEmpty);
      expect(avatarResult['message'], contains('Backend chưa hỗ trợ upload ảnh'));
      expect(await secureStorage.read(key: AppConstants.keyAvatarUrl), 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...');
    });

    // -------------------------------------------------------------
    // W4: KYC Endpoints Contract & Limits (MOB-005)
    // -------------------------------------------------------------
    test('W4: KYC uses /kyc/submit and /kyc/status; WalletRemoteDataSource parses dailyLimit and status', () async {
      expect(ApiConstants.kycSubmit, '/kyc/submit');
      expect(ApiConstants.kycStatus, '/kyc/status');

      final profileRemote = ProfileRemoteDataSource(dio: dio, storage: secureStorage);
      final walletRemote = WalletRemoteDataSource(dio: dio, storage: secureStorage);

      RequestOptions? submitOptions;
      RequestOptions? statusOptions;
      RequestOptions? walletOptions;

      adapter.handler = (options) {
        if (options.path == ApiConstants.kycSubmit) {
          submitOptions = options;
          return jsonResponse({'success': true, 'data': {'verificationStatus': 'PENDING'}});
        }
        if (options.path == ApiConstants.kycStatus) {
          statusOptions = options;
          return jsonResponse({'success': true, 'data': {'verificationStatus': 'VERIFIED', 'level': 2}});
        }
        if (options.path == ApiConstants.walletMe) {
          walletOptions = options;
          return jsonResponse({
            'success': true,
            'data': {
              'id': 'w-1',
              'ownerId': 'usr-1',
              'balance': 15000000,
              'dailyLimit': 50000000,
              'status': 'ACTIVE',
            },
          });
        }
        return jsonResponse({'success': true});
      };

      final submitRes = await profileRemote.submitKyc({'docType': 'CCCD', 'docNumber': '0123456789'});
      expect(submitOptions?.method, 'POST');
      expect(submitOptions?.path, '/kyc/submit');
      expect(submitRes['verificationStatus'], 'PENDING');

      final statusRes = await profileRemote.getKycStatus();
      expect(statusOptions?.method, 'GET');
      expect(statusOptions?.path, '/kyc/status');
      expect(statusRes?['verificationStatus'], 'VERIFIED');

      final wallet = await walletRemote.getMyWallet();
      expect(walletOptions?.method, 'GET');
      expect(wallet.dailyLimit, 50000000);
      expect(wallet.status, 'ACTIVE');
    });

    // -------------------------------------------------------------
    // W5: Money Request Contract (MOB-006)
    // -------------------------------------------------------------
    test('W5: MoneyRequestRemoteDataSource aligns with /payments/money-requests contract', () async {
      expect(ApiConstants.moneyRequests, '/payments/money-requests');
      expect(ApiConstants.moneyRequestsUser('usr-99'), '/payments/money-requests/user/usr-99');
      expect(ApiConstants.moneyRequestAccept('req-1'), '/payments/money-requests/req-1/accept');
      expect(ApiConstants.moneyRequestReject('req-1'), '/payments/money-requests/req-1/reject');

      final moneyRemote = MoneyRequestRemoteDataSource(dio: dio, storage: secureStorage);
      final capturedCalls = <RequestOptions>[];

      adapter.handler = (options) {
        capturedCalls.add(options);
        if (options.path.endsWith('/user/usr-99')) {
          return jsonResponse({
            'success': true,
            'data': [
              {'id': 'req-1', 'amount': 200000, 'status': 'PENDING'},
            ],
          });
        }
        return jsonResponse({'success': true, 'data': {'id': 'req-new'}});
      };

      // 1. Create
      await moneyRemote.create(
        requesterId: 'usr-sender',
        amount: 250000.0,
        targetUserId: 'usr-recipient',
        note: 'Tien an trua',
      );
      final createReq = capturedCalls.last;
      expect(createReq.path, '/payments/money-requests');
      expect(createReq.method, 'POST');
      expect(createReq.data['requesterId'], 'usr-sender');
      expect(createReq.data['targetUserId'], 'usr-recipient');
      expect(createReq.data['amount'], 250000.0);
      expect(createReq.data['note'], 'Tien an trua');

      // 2. Accept
      await moneyRemote.accept('req-1', payerUserId: 'usr-payer-1');
      final acceptReq = capturedCalls.last;
      expect(acceptReq.path, '/payments/money-requests/req-1/accept');
      expect(acceptReq.method, 'POST');
      expect(acceptReq.queryParameters['payerUserId'], 'usr-payer-1');

      // 3. Reject
      await moneyRemote.reject('req-1', payerUserId: 'usr-payer-1');
      final rejectReq = capturedCalls.last;
      expect(rejectReq.path, '/payments/money-requests/req-1/reject');
      expect(rejectReq.method, 'POST');
      expect(rejectReq.queryParameters['payerUserId'], 'usr-payer-1');

      // 4. GetReceived
      final received = await moneyRemote.getReceived(userId: 'usr-99');
      final getRecReq = capturedCalls.last;
      expect(getRecReq.path, '/payments/money-requests/user/usr-99');
      expect(getRecReq.method, 'GET');
      expect(received.length, 1);
      expect(received.first['id'], 'req-1');

      // 5. GetSent
      final sent = await moneyRemote.getSent();
      expect(sent, isEmpty);

      // 6. GetDetail & Cancel throw UnsupportedError
      expect(() => moneyRemote.getDetail('req-1'), throwsUnsupportedError);
      expect(() => moneyRemote.cancel('req-1'), throwsUnsupportedError);
    });

    // -------------------------------------------------------------
    // W6: Session Remote DataSource Contract (MOB-008)
    // -------------------------------------------------------------
    test('W6: SessionRemoteDataSource calls /sessions for get and /sessions/{id} for delete', () async {
      expect(ApiConstants.sessions, '/sessions');
      expect(ApiConstants.sessionDetail('s-123'), '/sessions/s-123');

      final sessionRemote = SessionRemoteDataSource(dio: dio);
      final capturedCalls = <RequestOptions>[];

      adapter.handler = (options) {
        capturedCalls.add(options);
        if (options.method == 'GET' && options.path == '/sessions') {
          return jsonResponse({
            'success': true,
            'data': [
              {'id': 's-1', 'deviceId': 'iphone-14', 'current': true},
              {'id': 's-2', 'deviceId': 'pixel-7', 'current': false},
            ],
          });
        }
        return jsonResponse({'success': true, 'data': {'revoked': true}});
      };

      // 1. GetSessions
      final sessions = await sessionRemote.getSessions();
      expect(capturedCalls.last.path, '/sessions');
      expect(capturedCalls.last.method, 'GET');
      expect(sessions.length, 2);

      // 2. Revoke individual session
      await sessionRemote.revokeSession('s-2');
      expect(capturedCalls.last.path, '/sessions/s-2');
      expect(capturedCalls.last.method, 'DELETE');

      // 3. Revoke all other sessions
      await sessionRemote.revokeAllOtherSessions(currentSessionId: 's-1');
      final deleteCalls = capturedCalls.where((c) => c.method == 'DELETE').toList();
      // s-2 được gọi xóa
      expect(deleteCalls.any((c) => c.path.contains('/sessions/s-2')), isTrue);
    });

    // -------------------------------------------------------------
    // W7: Notification Settings Contract (MOB-010)
    // -------------------------------------------------------------
    test('W7: NotificationRemoteDataSource updateSettings sends PUT /notifications/settings with query params', () async {
      expect(ApiConstants.notificationSettings, '/notifications/settings');

      final notifRemote = NotificationRemoteDataSource(dio: dio);
      RequestOptions? notifOptions;

      adapter.handler = (options) {
        notifOptions = options;
        return jsonResponse({'success': true, 'message': 'Notification settings updated'});
      };

      await notifRemote.updateSettings(
        transactionEnabled: true,
        promoEnabled: false,
      );

      expect(notifOptions, isNotNull);
      expect(notifOptions!.path, '/notifications/settings');
      expect(notifOptions!.method, 'PUT');
      expect(notifOptions!.queryParameters['transactionEnabled'], true);
      expect(notifOptions!.queryParameters['promoEnabled'], false);
    });
  });
}