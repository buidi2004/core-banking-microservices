import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:ekyc_sdk/ekyc_sdk.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/data/datasources/remote/ekyc_ai_remote_datasource.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late MockHttpClientAdapter adapter;
  late EkycAiRemoteDataSource dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
    adapter = MockHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    FlutterSecureStorage.setMockInitialValues({'user_id': 'usr-789-abc'});
    dataSource = EkycAiRemoteDataSource(dio: dio);
  });

  group('EkycAiRemoteDataSource Contract & Encryption Tests', () {
    test('checkHealth sends GET /ekyc/ai/health and parses response', () async {
      adapter.handler = (options) {
        expect(options.method, equals('GET'));
        expect(options.path, equals('/ekyc/ai/health'));
        return jsonResponse({
          'service': 'ekyc-ai-service',
          'status': 'UP',
          'provider': 'CPUExecutionProvider',
          'redisBacked': true,
        });
      };

      final health = await dataSource.checkHealth();
      expect(health['status'], equals('UP'));
      expect(health['redisBacked'], isTrue);
    });

    test('createSession sends POST /ekyc/ai/session with userId', () async {
      adapter.handler = (options) {
        expect(options.method, equals('POST'));
        expect(options.path, equals('/ekyc/ai/session'));
        final body = options.data as Map;
        expect(body['userId'], equals('usr-789-abc'));
        return jsonResponse({
          'sessionId': 'session-xyz-123',
          'nonce': 'nonce-val-456',
          'ttlSeconds': 240,
          'cryptoScheme': 'RSA-OAEP-SHA256 + AES-256-GCM',
        });
      };

      final session = await dataSource.createSession();
      expect(session.sessionId, equals('session-xyz-123'));
      expect(session.nonce, equals('nonce-val-456'));
      expect(session.ttlSeconds, equals(240));
    });

    test('verifyBiometrics encrypts payload with AES-256-GCM + RSA-OAEP', () async {
      const session = EkycSession(
        sessionId: 'session-xyz-123',
        nonce: 'nonce-val-456',
        ttlSeconds: 240,
        cryptoScheme: 'RSA-OAEP-SHA256 + AES-256-GCM',
      );

      adapter.handler = (options) {
        expect(options.method, equals('POST'));
        expect(options.path, equals('/ekyc/ai/verify'));
        final body = options.data as Map;
        expect(body['sessionId'], equals('session-xyz-123'));
        expect(body['nonce'], equals('nonce-val-456'));
        expect(body['wrappedKey'], isNotEmpty);
        expect(body['nonceB64'], isNotEmpty);
        expect(body['ciphertext'], isNotEmpty);

        return jsonResponse({
          'sessionId': 'session-xyz-123',
          'decision': 'APPROVED',
          'liveness': {'is_live': true, 'score': 0.99},
          'faceMatch': {'matched': true, 'similarity': 0.88},
          'latencyMs': 52,
        });
      };

      final result = await dataSource.verifyBiometrics(
        session: session,
        selfieBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        chipPhotoBytes: Uint8List.fromList([6, 7, 8, 9, 10]),
        documentNumber: '001202000001',
      );

      expect(result.decision, equals(EkycDecision.approved));
      expect(result.isLive, isTrue);
      expect(result.isMatched, isTrue);
      expect(result.livenessScore, closeTo(0.99, 0.01));
    });
  });
}
