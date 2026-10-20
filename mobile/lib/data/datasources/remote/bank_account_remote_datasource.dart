import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class BankAccountRemoteDataSource {
  final Dio _dio;

  BankAccountRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final response = await _dio.get(ApiConstants.bankAccounts);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> link({
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final response = await _dio.post(
      ApiConstants.bankAccountsLink,
      data: {
        'bankCode': bankCode,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<void> unlink(String bankAccountId) async {
    final response = await _dio.delete(ApiConstants.bankAccountDetail(bankAccountId));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }
}