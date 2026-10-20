import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final baseUrl = 'http://180.93.120.246:8080/api/v1';

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
    final token = jsonDecode(loginRes.body)['data']['accessToken'];
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
