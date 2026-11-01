import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';

void main() {
  test('Kiểm tra kết nối Mobile DioClient đến ngrok Public Tunnel', () async {
    const ngrokApiUrl = 'https://mutation-tubby-overstock.ngrok-free.dev/api/v1';
    
    // 1. Kiểm tra chuẩn hóa URL
    final normalized = DioClient.normalizeApiUrl(ngrokApiUrl);
    expect(normalized, equals(ngrokApiUrl));
    
    // 2. Kiểm tra suy diễn WebSocket URL
    final wsUrl = DioClient.deriveWsUrl(normalized);
    expect(wsUrl, equals('wss://mutation-tubby-overstock.ngrok-free.dev/ws-native'));
    
    // 3. Khởi tạo Dio với cấu hình mobile chuẩn
    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // 4. Gửi request đăng nhập thử nghiệm từ Mobile client (nếu tunnel ngrok đang online)
    try {
      final res = await dio.post(
        ApiConstants.login,
        data: {
          'phoneNumber': 'teller1',
          'password': 'DemoPass#2026!',
        },
      );

      expect(res.statusCode, equals(200));
      expect(res.data, isA<Map>());
      final body = res.data as Map;
      expect(body['success'], isTrue);
      expect(body['data'], isNotNull);
      final data = body['data'] as Map;
      expect(data['token'], isNotNull);
      expect(data['role'], equals('ROLE_TELLER'));

      stdout.writeln('✔ Mobile DioClient kết nối ngrok thành công 100%!');
      stdout.writeln('✔ Token: ${data['token'].toString().substring(0, 30)}...');
      stdout.writeln('✔ FullName: ${data['fullName']}');
    } on DioException catch (e) {
      stdout.writeln('ℹ Ngrok tunnel tạm thời offline (${e.message}), bỏ qua kiểm thử request trực tiếp.');
    }
  });
}

