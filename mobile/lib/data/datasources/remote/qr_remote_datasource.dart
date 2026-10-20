import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class QrRemoteDataSource {
  final Dio _dio;

  QrRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<String> getMyQr() async {
    final response = await _dio.get(ApiConstants.myQrCode);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! String) throw apiException(json);
    return json['data'] as String;
  }

  Future<Map<String, dynamic>> generateQr({required String accountNumber, String? bankBin, double? amount, String? purpose}) async {
    final response = await _dio.post(ApiConstants.generateVietQr, data: {
      'bankBin': bankBin ?? 'SENBANK',
      'accountNumber': accountNumber,
      if (amount != null) 'amount': amount,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> scanQr(String qrString) async {
    try {
      final response = await _dio.post('/payments/qr/scan', queryParameters: {'qrString': qrString});
      final json = Map<String, dynamic>.from(response.data as Map);
      if (json['success'] == true && json['data'] is Map) {
        return Map<String, dynamic>.from(json['data'] as Map);
      }
    } catch (_) {}
    return decodeQr(qrString);
  }

  Future<Map<String, dynamic>> decodeQr(String qrString) async {
    final response = await _dio.post(ApiConstants.decodeVietQr, queryParameters: {'qrString': qrString});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}