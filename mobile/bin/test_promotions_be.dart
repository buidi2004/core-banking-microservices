import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final baseUrl = Platform.environment['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';

  print('--- Testing GET /promotions ---');
  try {
    final res = await http.get(Uri.parse('$baseUrl/promotions'));
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }

  // Login to test my-vouchers
  print('\n--- Testing Auth & my-vouchers ---');
  try {
    final loginRes = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': '0976019781', 'password': 'Password123!'}),
    );
    final data = jsonDecode(loginRes.body)['data'];
    final token = (data?['token'] ?? data?['accessToken']) as String?;
    if (token == null) {
      print('Login error: ${loginRes.body}');
      return;
    }
    print('Logged in successfully, token: ${token.substring(0, 15)}...');

    final myVouchersRes = await http.get(
      Uri.parse('$baseUrl/promotions/my-vouchers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('my-vouchers Status: ${myVouchersRes.statusCode}');
    print('my-vouchers Body: ${myVouchersRes.body}');

    // Test redeem
    final redeemRes = await http.post(
      Uri.parse('$baseUrl/promotions/redeem?code=WELCOME'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('redeem Status: ${redeemRes.statusCode}');
    print('redeem Body: ${redeemRes.body}');
  } catch (e) {
    print('Auth error: $e');
  }
}
