import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyInterceptor extends Interceptor {
  final Uuid _uuid = const Uuid();

  static const List<String> _idempotentPaths = [
    '/wallets/deposit',
    '/wallets/transfer/init',
    '/wallets/transfer/',
    '/wallets/withdraw',
    '/bills/pay',
    '/bills/topup',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'POST') {
      final isIdempotentEndpoint = _idempotentPaths.any((path) => options.path.contains(path));
      if (isIdempotentEndpoint && !options.headers.containsKey('Idempotency-Key')) {
        options.headers['Idempotency-Key'] = _uuid.v4();
      }
    }
    handler.next(options);
  }
}
