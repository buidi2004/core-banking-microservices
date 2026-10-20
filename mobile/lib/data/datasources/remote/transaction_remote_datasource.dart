import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class TransactionRemoteDataSource {
  final Dio _dio;

  TransactionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getTransactions({
    required String walletId,
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    final res = await getTransactionsPage(walletId: walletId, type: type, page: page, size: size);
    return res['items'] as List<Map<String, dynamic>>;
  }

  Future<Map<String, dynamic>> getTransactionsPage({
    required String walletId,
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.transactions,
      queryParameters: {
        'walletId': walletId,
        if (type != null) 'type': type,
        'page': page,
        'size': size,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    final data = json['data'];
    List rawList = [];
    bool isLast = false;
    int totalElements = 0;
    int totalPages = 1;

    if (data is List) {
      rawList = data;
      isLast = rawList.length < size;
      totalElements = rawList.length;
    } else if (data is Map) {
      if (data['content'] is List) {
        rawList = data['content'] as List;
      }
      isLast = (data['last'] ?? data['isLast'] ?? (rawList.length < size)) == true;
      totalElements = (data['totalElements'] as num?)?.toInt() ?? rawList.length;
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    } else if (json['success'] != true) {
      throw apiException(json);
    }

    final items = rawList.map((item) => _mapTransaction(Map<String, dynamic>.from(item as Map))).toList();
    final finalItems = (data is List && items.length > size) ? items.take(size).toList() : items;
    return {
      'items': finalItems,
      'isLast': isLast,
      'page': page,
      'totalElements': totalElements,
      'totalPages': totalPages,
    };
  }

  Future<Map<String, dynamic>> getTransaction(String id) async {
    final response = await _dio.get(ApiConstants.transactionDetail(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return _mapTransaction(Map<String, dynamic>.from(json['data'] as Map));
  }

  Future<List<int>> exportTransactions({required String walletId, required String format}) async {
    final response = await _dio.get<List<int>>(
      ApiConstants.exportTransactions(format),
      queryParameters: {'walletId': walletId},
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null) throw Exception('Không nhận được file sao kê từ backend');
    return response.data!;
  }

  Future<List<int>> getReceipt(String transactionId) async {
    final response = await _dio.get<List<int>>(
      ApiConstants.receiptPdf(transactionId),
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null) throw Exception('Không nhận được biên lai từ backend');
    return response.data!;
  }

  Map<String, dynamic> _mapTransaction(Map<String, dynamic> item) {
    final type = (item['type'] as String? ?? 'TRANSFER_OUT').toUpperCase();
    final rawAmount = (item['amount'] as num?)?.toDouble() ?? 0;
    final isIncoming = type == 'TRANSFER_IN' || type == 'DEPOSIT';
    final counterparty = item['counterpartyName'] ?? item['recipientName'] ?? item['senderName'];
    final title = isIncoming
        ? (type == 'DEPOSIT' ? 'Nạp tiền vào ví' : 'Nhận tiền từ ${counterparty ?? 'người gửi'}')
        : (type == 'WITHDRAWAL' ? 'Rút tiền về ngân hàng' : 'Chuyển tiền tới ${counterparty ?? 'người nhận'}');
    final note = (item['note'] ?? item['content'] ?? item['desc'] ?? item['description'] ?? '').toString();
    final displayDesc = note.isNotEmpty
        ? note
        : (counterparty != null && counterparty.toString().isNotEmpty
            ? (isIncoming ? 'Từ: $counterparty' : 'Tới: $counterparty')
            : (type == 'DEPOSIT' ? 'Nạp tiền vào ví thành công' : 'Giao dịch thành công'));
    final balance = (item['runningBalance'] ?? item['balance'] ?? item['balanceAfter'] as num?)?.toDouble();

    return {
      'id': (item['transactionId'] ?? item['id'] ?? '').toString(),
      'requestId': item['requestId']?.toString() ?? '',
      'targetWalletId': item['targetWalletId']?.toString() ?? '',
      'title': title,
      'desc': displayDesc,
      'note': note,
      'amount': isIncoming ? rawAmount : -rawAmount.abs(),
      'rawAmount': rawAmount,
      'currency': item['currency']?.toString() ?? 'VND',
      'date': item['timestamp'] ?? item['createdAt'] ?? '',
      'type': type.toLowerCase(),
      'status': item['status'] ?? 'SUCCESS',
      'runningBalance': balance,
      'senderName': item['senderName']?.toString() ?? '',
      'recipientName': item['recipientName']?.toString() ?? '',
      'recipientAccount': item['recipientAccount']?.toString() ?? '',
      'counterpartyName': counterparty ?? '',
      'counterpartyAccount': (item['counterpartyAccount'] ?? item['recipientAccount'] ?? item['senderAccount'] ?? '').toString(),
      'bankCode': (item['counterpartyBankName'] ?? item['bankCode'] ?? 'SENHONG').toString(),
      'counterpartyBankName': (item['counterpartyBankName'] ?? item['bankCode'] ?? 'SenHong').toString(),
      'isInternal': item['isInternal'] ?? true,
      'raw': item,
    };
  }
}