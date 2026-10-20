import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class LoanRemoteDataSource {
  final Dio _dio;

  LoanRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _dio.get(ApiConstants.loanProducts);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> applyLoan({
    required String walletId,
    required String productType,
    required double amount,
    required int termMonths,
    String? purpose,
    String? pinToken,
  }) async {
    final response = await _dio.post(
      ApiConstants.loanApply,
      data: {
        'walletId': walletId,
        'productType': productType,
        'amount': amount,
        'termMonths': termMonths,
        if (purpose != null) 'purpose': purpose,
        if (pinToken != null && pinToken.isNotEmpty) 'pinToken': pinToken,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getUserLoans() async {
    final response = await _dio.get(ApiConstants.loans);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getLoanDetail(String id) async {
    final response = await _dio.get(ApiConstants.loanDetail(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> getLoanSchedule(String id) async {
    final response = await _dio.get(ApiConstants.loanSchedule(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> repayTerm(
    String id, {
    required int termNumber,
    double? amount,
    String? pinToken,
  }) async {
    final response = await _dio.post(
      ApiConstants.loanRepay(id),
      data: {
        'termNumber': termNumber,
        if (amount != null) 'amount': amount,
        if (pinToken != null && pinToken.isNotEmpty) 'pinToken': pinToken,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}

