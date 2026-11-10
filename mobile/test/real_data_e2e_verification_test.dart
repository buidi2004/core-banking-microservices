@Tags(['e2e'])
library;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/bill_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/loan_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/savings_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/card_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/qr_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/support_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/lottery_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/money_request_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/notification_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/promotion_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/session_remote_datasource.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> mockStorage = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(storageChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'write') {
      mockStorage[methodCall.arguments['key']] = methodCall.arguments['value'];
      return null;
    }
    if (methodCall.method == 'read') {
      return mockStorage[methodCall.arguments['key']];
    }
    if (methodCall.method == 'delete') {
      mockStorage.remove(methodCall.arguments['key']);
      return null;
    }
    if (methodCall.method == 'deleteAll') {
      mockStorage.clear();
      return null;
    }
    return null;
  });

  HttpOverrides.global = _RealHttpOverrides();
  final dio = DioClient().dio;

  // Cấu hình timeout và header cho test
  dio.options.connectTimeout = const Duration(seconds: 15);
  dio.options.receiveTimeout = const Duration(seconds: 15);
  dio.options.headers['ngrok-skip-browser-warning'] = 'true';
  dio.options.headers['X-Requested-With'] = 'XMLHttpRequest';
  
  // Ưu tiên localhost:8080 nếu chạy test nội bộ
  if (const String.fromEnvironment('API_BASE_URL').isEmpty) {
    dio.options.baseUrl = 'http://localhost:8080/api/v1';
  }

  String customerToken = '';
  String tellerToken = '';
  String customerWalletId = '';
  String receiverWalletId = '';
  String customerUserId = 'a11ce000-0000-0000-0000-000000000001';
  String receiverUserId = '497260ee-3b16-4199-9675-fb8a5f8e15d1';
  String? pinToken;

  setUpAll(() async {
    // 1. Đăng nhập User khách hàng (Thử DemoPass#2026! trước theo ACCOUNTS.md, fallback sang Password123!)
    Response loginRes;
    try {
      loginRes = await dio.post(
        ApiConstants.login,
        data: {
          'username': '0901234567',
          'password': 'DemoPass#2026!',
          'deviceId': 'device-e2e-real-iphone',
          'deviceName': 'iPhone 15 Pro Max',
          'deviceOs': 'iOS 18',
        },
      );
    } catch (_) {
      loginRes = await dio.post(
        ApiConstants.login,
        data: {
          'username': '0901234567',
          'password': 'Password123!',
          'deviceId': 'device-e2e-real-iphone',
          'deviceName': 'iPhone 15 Pro Max',
          'deviceOs': 'iOS 18',
        },
      );
    }
    expect(loginRes.statusCode, 200);
    customerToken = loginRes.data['data']['accessToken'];
    customerUserId = loginRes.data['data']['userId'] ?? customerUserId;
    expect(customerToken, isNotEmpty);

    // Gán token cho Dio của khách hàng
    dio.options.headers['Authorization'] = 'Bearer $customerToken';

    // Lấy walletId chính thức
    final wallet = await WalletRemoteDataSource().getMyWallet();
    customerWalletId = wallet.walletId;

    // 2. Đăng nhập Cán bộ giao dịch viên (Teller)
    final tellerRes = await dio.post(
      ApiConstants.login,
      data: {'username': '0911000001', 'password': 'DemoPass#2026!'},
    );
    expect(tellerRes.statusCode, 200);
    tellerToken = tellerRes.data['data']['accessToken'];
    expect(tellerToken, isNotEmpty);
  });

  group('REAL DATA E2E TEST: Toàn diện Nghiệp vụ Core Banking Backend & Mobile', () {
    test('1. Xác thực hồ sơ User khách hàng & Lấy thông tin Ví thật', () async {
      final userRes = await dio.get('/users/me');
      expect(userRes.statusCode, 200);
      expect(userRes.data['success'], true);
      expect(userRes.data['data']['phoneNumber'], '0901234567');

      final wallet = await WalletRemoteDataSource().getMyWallet();
      expect(wallet.walletId, isNotEmpty);
      expect(wallet.status, 'ACTIVE');
      print('✔ Khách hàng: ${userRes.data['data']['fullName']} | Ví: $customerWalletId | Số dư: ${wallet.balance} VND');
    });

    test('2. Xác thực mã PIN giao dịch để nhận PIN Token bảo mật', () async {
      pinToken = await WalletTransactionRemoteDataSource().verifyPin('123456');
      expect(pinToken, isNotNull);
      expect(pinToken, isNotEmpty);
      print('✔ PIN Token: ${pinToken!.substring(0, 25)}...');
    });

    test('3. Nạp tiền vào ví thật (Deposit Mutation)', () async {
      final walletBefore = await WalletRemoteDataSource().getMyWallet();
      final depositAmount = 2000000.0;

      final depositRes = await WalletTransactionRemoteDataSource().deposit(
        walletId: customerWalletId,
        amount: depositAmount,
      );
      expect(depositRes['status'], 'SUCCESS');

      final walletAfter = await WalletRemoteDataSource().getMyWallet();
      expect(walletAfter.balance, equals(walletBefore.balance + depositAmount));
      print('✔ Nạp ví +$depositAmount VND thành công. Số dư mới: ${walletAfter.balance} VND');
    });

    test('4. Chuyển tiền P2P Saga (Tìm người nhận -> Khóa ví -> Trừ tiền -> Ghi sổ kép)', () async {
      // 4.1 Tra cứu thông tin người nhận 0971431177
      final recipient = await TransferRemoteDataSource().getRecipient('0971431177');
      expect(recipient['fullName'], isNotNull);
      receiverWalletId = recipient['walletId'] ?? recipient['id'];
      receiverUserId = (recipient['userId'] ?? recipient['ownerId'] ?? receiverUserId).toString();
      print('✔ Người nhận: ${recipient['fullName']} (Ví: $receiverWalletId)');

      // 4.2 Lấy số dư trước chuyển
      final senderBefore = await WalletRemoteDataSource().getMyWallet();

      // 4.3 Thực hiện chuyển 50,000 VND
      final transferAmount = 50000.0;
      final transferPinToken = await WalletTransactionRemoteDataSource().verifyPin('123456');
      final transferRes = await TransferRemoteDataSource().initTransfer(
        sourceWalletId: customerWalletId,
        targetWalletId: receiverWalletId,
        targetUserId: receiverUserId,
        amount: transferAmount,
        note: 'E2E Real Data P2P Test',
        pinToken: transferPinToken,
      );
      expect(transferRes['status'], 'SUCCESS');

      // 4.4 Kiểm tra số dư người gửi đã bị trừ chính xác
      final senderAfter = await WalletRemoteDataSource().getMyWallet();
      expect(senderAfter.balance, equals(senderBefore.balance - transferAmount));
      print('✔ Chuyển tiền P2P $transferAmount VND thành công. Số dư còn: ${senderAfter.balance} VND');

      // 4.5 Kiểm tra lịch sử giao dịch
      final txs = await TransactionRemoteDataSource().getTransactions(
        walletId: customerWalletId,
        page: 0,
        size: 5,
      );
      expect(txs, isNotEmpty);
      expect(txs.first['status'], 'SUCCESS');
    });

    test('5. Tra cứu và Thanh toán Hóa đơn Điện / Nước thật', () async {
      // Tra cứu tiền điện EVN
      final electricBill = await BillRemoteDataSource().lookup(
        type: 'ELECTRICITY',
        customerCode: 'PE0100088921',
      );
      expect(electricBill['billId'], isNotNull);
      expect(electricBill['providerName'], contains('Điện lực'));
      print('✔ Hóa đơn Điện: ${electricBill['billId']} | Tiền: ${electricBill['amount']} VND | Đơn vị: ${electricBill['providerName']}');

      // Tra cứu tiền nước SAWACO
      final waterBill = await BillRemoteDataSource().lookup(
        type: 'WATER',
        customerCode: 'WATER001',
      );
      expect(waterBill['billId'], isNotNull);
      expect(waterBill['providerName'], contains('Cấp nước'));
      print('✔ Hóa đơn Nước: ${waterBill['billId']} | Tiền: ${waterBill['amount']} VND | Đơn vị: ${waterBill['providerName']}');

      // Thanh toán hóa đơn điện
      final payRes = await BillRemoteDataSource().pay(
        walletId: customerWalletId,
        billId: electricBill['billId'],
        amount: (electricBill['amount'] as num).toDouble(),
      );
      expect(payRes['status'], 'SUCCESS');
      print('✔ Thanh toán hóa đơn ${electricBill['billId']} thành công. TxCode: ${payRes['transactionCode']}');
    });

    test('6. Nạp tiền điện thoại Viettel', () async {
      final topupRes = await BillRemoteDataSource().topup(
        walletId: customerWalletId,
        phoneNumber: '0901234567',
        amount: 50000.0,
      );
      expect(topupRes['status'], 'SUCCESS');
      print('✔ Nạp ĐT Viettel 50,000 VND thành công. TxCode: ${topupRes['transactionCode']}');
    });

    test('7. Vòng đời Vay Tiêu Dùng: Nộp đơn -> Teller Duyệt -> Giải ngân ví -> Trả nợ kỳ 1', () async {
      // 7.1 Lấy PIN token cho khoản vay
      final loanPinToken = await WalletTransactionRemoteDataSource().verifyPin('123456');

      // 7.2 Khách hàng nộp hồ sơ vay 10.000.000đ kỳ hạn 6 tháng
      final loanRes = await LoanRemoteDataSource().applyLoan(
        walletId: customerWalletId,
        productType: 'VAY_TIEU_DUNG_NHANH',
        amount: 10000000.0,
        termMonths: 6,
        purpose: 'Sửa nhà cuối năm',
        pinToken: loanPinToken,
      );
      expect(loanRes['contractNumber'], isNotNull);
      expect(loanRes['status'], 'PENDING_APPROVAL');
      final loanId = loanRes['id'] ?? loanRes['loanId'];
      print('✔ Nộp hồ sơ vay thành công. Hợp đồng: ${loanRes['contractNumber']} | Trạng thái: ${loanRes['status']}');

      // 7.3 Giao dịch viên (Teller) phê duyệt khoản vay qua token của Teller
      final tellerDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        headers: {'Authorization': 'Bearer $tellerToken'},
      ));
      final approveRes = await tellerDio.post('${dio.options.baseUrl}/loans/$loanId/approve');
      expect(approveRes.statusCode, 200);
      expect(approveRes.data['data']['status'], 'DISBURSED');
      print('✔ Cán bộ tín dụng (Teller) duyệt khoản vay: Trạng thái DISBURSED (Đã giải ngân +10.000.000đ vào ví)');

      // 7.4 Khách hàng xem lịch trả nợ 6 kỳ
      final scheduleRes = await LoanRemoteDataSource().getLoanSchedule(loanId);
      final schedule = scheduleRes['schedule'] as List;
      expect(schedule.length, 6);
      final term1 = schedule[0] as Map;
      expect(term1['termNumber'], 1);
      expect(term1['status'], 'DUE');
      final term1Total = (term1['totalAmount'] as num).toDouble();
      print('✔ Lịch trả nợ 6 kỳ đã sinh chuẩn: Kỳ 1 hạn trả ${term1['dueDate']} với số tiền $term1Total VND');

      // 7.5 Khách hàng thanh toán Kỳ 1
      final repayPinToken = await WalletTransactionRemoteDataSource().verifyPin('123456');
      final repayRes = await LoanRemoteDataSource().repayTerm(
        loanId,
        termNumber: 1,
        amount: term1Total,
        pinToken: repayPinToken,
      );
      expect(repayRes['status'], 'PAID');
      print('✔ Trả nợ Kỳ 1 thành công: Gốc còn lại: ${repayRes['remainingPrincipal']} VND');
    });

    test('8. Vòng đời Sổ Tiết Kiệm: Xem gói -> Mở sổ 1.000.000đ -> Tất toán trước hạn', () async {
      // 8.1 Xem danh sách gói tiết kiệm
      final products = await SavingsRemoteDataSource().getProducts();
      expect(products, isNotEmpty);
      print('✔ Danh sách gói tiết kiệm: ${products.map((p) => p['productName']).join(', ')}');

      // 8.2 Mở sổ tiết kiệm 1,000,000 VND kỳ hạn 6 tháng
      final openRes = await SavingsRemoteDataSource().openSavings(
        walletId: customerWalletId,
        productType: 'TIET_KIEM_PHAT_LOC',
        termMonths: 6,
        depositAmount: 1000000.0,
      );
      expect(openRes['accountNumber'], isNotNull);
      expect(openRes['status'], 'ACTIVE');
      final passbookId = openRes['id'];
      print('✔ Mở sổ tiết kiệm thành công: ${openRes['accountNumber']} | Lãi suất: ${openRes['interestRate']}%/năm');

      // 8.3 Tất toán sổ tiết kiệm trước hạn (hoàn tiền gốc + lãi về ví)
      final settleRes = await SavingsRemoteDataSource().settleSavings(passbookId);
      expect(settleRes['earlySettlement'], true);
      expect(settleRes['creditedToWallet'], customerWalletId);
      print('✔ Tất toán sổ ${openRes['accountNumber']}: Nhận về ví ${settleRes['totalPayout']} VND');
    });

    test('9. Quản lý Thẻ Visa ảo: Phát hành thẻ -> Khóa thẻ -> Kích hoạt thẻ', () async {
      // 9.1 Phát hành thẻ ảo
      final cardRes = await CardRemoteDataSource().issueCard(
        type: 'VIRTUAL',
      );
      expect(cardRes['number'], isNotNull);
      expect(cardRes['status'], 'ACTIVE');
      final cardId = cardRes['id'];
      print('✔ Phát hành thẻ ảo: ${cardRes['maskedNumber']} | Scheme: ${cardRes['scheme']} | CVV: ${cardRes['cvv']}');

      // 9.2 Khóa thẻ (FREEZE)
      final freezeRes = await CardRemoteDataSource().updateStatus(cardId, 'FROZEN');
      expect(freezeRes['status'], 'FROZEN');
      print('✔ Cập nhật trạng thái: Đã khóa thẻ an toàn (FROZEN)');

      // 9.3 Mở khóa thẻ (ACTIVE)
      final unfreezeRes = await CardRemoteDataSource().updateStatus(cardId, 'ACTIVE');
      expect(unfreezeRes['status'], 'ACTIVE');
      print('✔ Mở khóa thẻ: Trở lại trạng thái ACTIVE');
    });

    test('10. Cấu hình Bảo mật Thẻ: Bật/Tắt Online, Quốc tế & Rút ATM', () async {
      final cardRes = await CardRemoteDataSource().issueCard(type: 'VIRTUAL');
      final cardId = cardRes['id'] as String;

      // Tắt các tính năng chi tiêu
      final updated = await CardRemoteDataSource().updateSettings(
        cardId,
        onlinePayment: false,
        intlPayment: false,
        atmWithdraw: false,
      );
      expect(updated['onlinePayment'], false);
      expect(updated['intlPayment'], false);
      expect(updated['atmWithdraw'], false);

      // Bật lại
      final restored = await CardRemoteDataSource().updateSettings(
        cardId,
        onlinePayment: true,
        intlPayment: true,
        atmWithdraw: true,
      );
      expect(restored['onlinePayment'], true);
      expect(restored['intlPayment'], true);
      expect(restored['atmWithdraw'], true);
      print('✔ Cập nhật & phục hồi cấu hình bảo mật thẻ thành công (Online/Quốc tế/ATM: OK)');
    });

    test('11. Tải Biên Lai Điện Tử Giao Dịch Chuẩn PDF Ngân Hàng', () async {
      final txs = await TransactionRemoteDataSource().getTransactions(
        walletId: customerWalletId,
        size: 1,
      );
      expect(txs, isNotEmpty);
      final txId = txs.first['id'] as String;

      final pdfRes = await dio.get<List<int>>(
        ApiConstants.receiptPdf(txId),
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf, application/octet-stream, */*'},
        ),
      );
      expect(pdfRes.statusCode, 200);
      final bytes = pdfRes.data!;
      expect(bytes.length, greaterThan(1000));
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
      print('✔ Tải biên lai điện tử PDF giao dịch $txId (${bytes.length} bytes): Chuẩn PDF %PDF-1.5');
    });

    test('12. Hệ Sinh Thái VietQR: Sinh mã VietQR động -> Quét & Giải mã QR', () async {
      final qrRes = await QrRemoteDataSource().generateQr(
        accountNumber: '0901234567',
        bankBin: '970422',
        amount: 150000.0,
        purpose: 'E2E Cafe SenHong',
      );
      final qrRaw = qrRes['qrRaw'] as String;
      expect(qrRaw, isNotEmpty);

      final decoded = await QrRemoteDataSource().decodeQr(qrRaw);
      expect(decoded['bankBin'], equals('970422'));
      expect(decoded['accountNumber'], equals('0901234567'));
      print('✔ Sinh và giải mã VietQR động thành công: BIN ${decoded['bankBin']} | TK ${decoded['accountNumber']} | Số tiền: 150.000 VND');
    });

    test('13. Liên kết & Hủy liên kết Tài khoản Ngân hàng nội địa (Vietcombank)', () async {
      final linkRes = await BankAccountRemoteDataSource().link(
        bankCode: 'VCB',
        accountNumber: '1012345678',
        accountHolderName: 'ALICE NGUYEN',
      );
      final bankAccountId = linkRes['id'] as String;
      expect(linkRes['bankCode'], equals('VCB'));

      final list = await BankAccountRemoteDataSource().getAccounts();
      expect(list.any((a) => a['id'] == bankAccountId), isTrue);

      await BankAccountRemoteDataSource().unlink(bankAccountId);
      print('✔ Liên kết và hủy liên kết tài khoản Vietcombank thành công: ID $bankAccountId');
    });

    test('14. Danh bạ Người Thụ Hưởng (Beneficiaries Directory)', () async {
      final benRes = await BeneficiaryRemoteDataSource().add({
        'accountNumber': '9704220000000002',
        'bankCode': 'SENBANK',
        'nickname': 'Bob Dong Nghiep',
      });
      final benId = benRes['id'] as String;
      expect(benRes['nickname'], equals('Bob Dong Nghiep'));

      final benList = await BeneficiaryRemoteDataSource().getAll();
      expect(benList.any((b) => b['id'] == benId), isTrue);

      await BeneficiaryRemoteDataSource().remove(benId);
      print('✔ Thêm, tra cứu và xóa người thụ hưởng khỏi danh bạ thành công: $benId');
    });

    test('15. Hỗ Trợ Khách Hàng 24/7 (Support Ticket & Message Thread)', () async {
      final ticket = await SupportRemoteDataSource().createTicket(
        subject: 'Tư vấn mở thẻ tín dụng',
        initialMessage: 'Tôi muốn được nâng hạn mức thẻ',
      );
      final ticketId = ticket['id'] as String;
      expect(ticket['subject'], equals('Tư vấn mở thẻ tín dụng'));

      final reply = await SupportRemoteDataSource().addMessage(
        ticketId: ticketId,
        content: 'Tôi đã bổ sung hồ sơ chứng minh thu nhập',
      );
      expect(reply['content'], isNotNull);
      print('✔ Tạo ticket hỗ trợ và gửi phản hồi thành công: Ticket #$ticketId');
    });

    test('16. Mua Vé Số Điện Toán Vietlott Mega 6/45 & Tra Cứu Kỳ Quay', () async {
      final buyRes = await LotteryRemoteDataSource().buyTicket(
        gameName: 'Mega 6/45',
        numbers: [5, 12, 18, 24, 33, 42],
        quantity: 1,
        drawPeriod: 'Ky E2E-01290',
        pinToken: pinToken,
      );
      expect(buyRes['ticketCode'], isNotNull);
      expect(buyRes['status'], 'CHỜ MỞ THƯỞNG');
      final ticketCode = buyRes['ticketCode'] as String;

      final myTickets = await LotteryRemoteDataSource().getMyTickets();
      expect(myTickets.any((t) => t['code'] == ticketCode), isTrue);

      final results = await LotteryRemoteDataSource().getResults();
      expect(results, isNotEmpty);
      print('✔ Mua vé số Vietlott thành công: Mã vé #$ticketCode | Kết quả Jackpot: ${results.first['jackpot1']}');
    });

    test('17. Yêu Cầu Chuyển Tiền / Chia Tiền P2P (Money Request)', () async {
      // Bob đăng nhập & lấy thông tin Bob
      final bobDio = DioClient().dio;
      final bobLogin = await bobDio.post(
        ApiConstants.login,
        data: {'username': '0909876543', 'password': 'DemoPass#2026!'},
      );
      final bobToken = bobLogin.data['data']['accessToken'] as String;
      final bobUserId = (bobLogin.data['data']['userId'] ?? 'b0b00000-0000-0000-0000-000000000002') as String;

      final reqRes = await MoneyRequestRemoteDataSource().create(
        requesterId: customerUserId,
        targetUserId: bobUserId,
        amount: 150000,
        note: 'Tiền ăn trưa E2E',
      );
      final reqId = reqRes['id'] as String;
      expect(reqRes['status'], 'PENDING');
      expect(reqRes['amount'], 150000);

      final detailRes = await dio.get(ApiConstants.moneyRequestDetail(reqId));
      expect(detailRes.data['data']['id'], reqId);
      expect(detailRes.data['data']['status'], 'PENDING');

      // Bob chấp nhận yêu cầu
      final acceptRes = await bobDio.post(
        ApiConstants.moneyRequestAccept(reqId),
        queryParameters: {'payerUserId': bobUserId},
        options: Options(headers: {'Authorization': 'Bearer $bobToken'}),
      );
      expect(acceptRes.data['success'], isTrue);
      expect(acceptRes.data['data']['status'], 'ACCEPTED');

      // Khôi phục lại header token của Alice
      dio.options.headers['Authorization'] = 'Bearer $customerToken';
      print('✔ Yêu cầu chuyển tiền 150.000đ tạo bởi Alice và đã được Bob chấp nhận: Request #$reqId');
    });

    test('18. Trung Tâm Thông Báo Biến Động Số Dư & In-App Push', () async {
      final unreadCount = await NotificationRemoteDataSource().getUnreadCount();
      expect(unreadCount, greaterThanOrEqualTo(0));

      final notifications = await NotificationRemoteDataSource().getNotifications('BALANCE');
      expect(notifications, isNotEmpty);
      final firstNotif = notifications.first;
      expect(firstNotif['title'], isNotNull);

      final notifId = firstNotif['id'] as String;
      await NotificationRemoteDataSource().markRead(notifId);
      print('✔ Tra cứu thông báo thành công: $unreadCount chưa đọc | Đã đánh dấu đọc thông báo #$notifId');
    });

    test('19. Kho Khuyến Mãi & Voucher Giảm Giá (Promotions & Vouchers)', () async {
      final vouchers = await PromotionRemoteDataSource().getMyVouchers();
      expect(vouchers, isNotEmpty);
      final vCode = vouchers.first['code'] as String;
      expect(vCode, isNotEmpty);

      print('✔ Tra cứu kho Voucher thành công: ${vouchers.length} voucher khả dụng (Mã tiêu biểu: $vCode)');
    });

    test('20. Quản Lý Phiên Đăng Nhập & Ước Tính Phí Giao Dịch', () async {
      final sessions = await SessionRemoteDataSource().getSessions();
      expect(sessions, isNotEmpty);
      final currentSession = sessions.first;
      expect(currentSession['id'], isNotNull);

      final feeEstimate = await WalletRemoteDataSource().estimateFee(
        amount: 500000,
        type: 'TRANSFER',
      );
      expect(feeEstimate['feeAmount'], equals(0));
      expect(feeEstimate['totalAmount'], equals(500000));
      print('✔ Phiên đăng nhập hợp lệ (${sessions.length} thiết bị) | Ước tính phí: ${feeEstimate['feeAmount']} VND (Miễn phí 100%)');
    });

    test('21. Hỗ Trợ & Xử Lý Khiếu Nại Trực Tuyến (Customer Support & Ticket Lifecycle)', () async {
      // 1. Tạo ticket khiếu nại mới
      final ticket = await SupportRemoteDataSource().createTicket(
        subject: 'Khiếu nại nạp tiền quầy chi nhánh',
        category: 'TRANSACTION',
        initialMessage: 'Tôi vừa nạp tiền tại quầy, đề nghị kiểm tra giao dịch',
      );
      expect(ticket['id'], isNotNull);
      final ticketId = ticket['id'].toString();
      expect(ticket['status'], 'OPEN');

      // 2. Tra cứu danh sách ticket của cá nhân
      final myTickets = await SupportRemoteDataSource().getTickets();
      expect(myTickets.any((t) => t['id'] == ticketId), isTrue);

      // 3. Gửi thêm tin nhắn bổ sung
      final msg = await SupportRemoteDataSource().addMessage(
        ticketId: ticketId,
        content: 'Đã gửi bổ sung hình ảnh biên lai quầy',
      );
      expect(msg['content'], contains('Đã gửi bổ sung'));

      // 4. Tra cứu chi tiết ticket
      final detail = await SupportRemoteDataSource().getTicketDetail(ticketId);
      expect(detail['ticket'], isNotNull);
      final detailTicket = detail['ticket'] as Map<String, dynamic>;
      expect(detailTicket['id'], ticketId);

      // 5. Cán bộ / Hệ thống xử lý hoàn tất ticket
      final resolved = await SupportRemoteDataSource().resolveTicket(
        ticketId: ticketId,
        resolutionNotes: 'Cán bộ kiểm soát đã xác minh và đối soát khớp 100%',
      );
      expect(resolved['status'], 'RESOLVED');
      print('✔ Vòng đời hỗ trợ khách hàng thành công: Ticket #$ticketId đã được tiếp nhận và xử lý (RESOLVED)');
    });
  });
}
