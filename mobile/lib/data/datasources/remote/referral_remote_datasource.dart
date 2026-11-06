import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class ReferralRemoteDataSource {
  final Dio _dio;

  ReferralRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<Map<String, dynamic>> getReferralCode() async {
    final response = await _dio.get(ApiConstants.referralCode);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getReferralHistory() async {
    final response = await _dio.get(ApiConstants.referralHistory);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
    final data = json['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map && data['invitedUsers'] is List) {
      return (data['invitedUsers'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> apply(String referralCode) async {
    final response = await _dio.post(
      ApiConstants.applyReferral,
      data: {'code': referralCode, 'referralCode': referralCode},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<void> applyReferral(String referralCode) => apply(referralCode);
}
