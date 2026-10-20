import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String baseUrl = 'http://180.93.120.246:8080/api/v1';

void main() async {
  final client = HttpClient();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final phone = '098${ts.toString().substring(5, 12)}';
  final receiverPhone = '097${(ts + 1).toString().substring(5, 12)}';

  print('\x1B[36m=================================================================\x1B[0m');
  print('\x1B[1m  SEN HỒNG E-WALLET BACKEND HEALTH CHECK & TEST SUITE  \x1B[0m');
  print('  VPS Target : $baseUrl');
  print('  Test Phone : $phone');
  print('  Date/Time  : ${DateTime.now().toIso8601String()}');
  print('\x1B[36m=================================================================\x1B[0m\n');

  int passed = 0;
  int failed = 0;

  Future<Map<String, dynamic>> req({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    String? token,
  }) async {
    var uriStr = '$baseUrl$path';
    if (query != null && query.isNotEmpty) {
      final qs = query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      uriStr += '?$qs';
    }
    final uri = Uri.parse(uriStr);

    final r = await (switch (method.toUpperCase()) {
      'POST' => client.postUrl(uri),
      'PUT' => client.putUrl(uri),
      'PATCH' => client.patchUrl(uri),
      'DELETE' => client.deleteUrl(uri),
      _ => client.getUrl(uri),
    });

    r.headers.contentType = ContentType.json;
    if (token != null) r.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    if (headers != null) headers.forEach((k, v) => r.headers.set(k, v));
    if (body != null) r.write(jsonEncode(body));

    final res = await r.close();
    final ct = res.headers.contentType?.mimeType ?? '';
    if (ct.contains('application/pdf') || ct.contains('text/csv')) {
      final bytes = await res.fold<List<int>>([], (p, e) => p..addAll(e));
      return {'status': res.statusCode, 'bytes': bytes, 'isBinary': true};
    }
    final bodyStr = await res.transform(utf8.decoder).join();
    dynamic parsed;
    try {
      parsed = jsonDecode(bodyStr);
    } catch (_) {
      parsed = bodyStr;
    }
    return {'status': res.statusCode, 'body': parsed, 'isBinary': false};
  }

  void check(String name, bool condition, [String? extra]) {
    if (condition) {
      passed++;
      print('  \x1B[32m✔ [PASS]\x1B[0m $name ${extra != null ? "(\x1B[90m$extra\x1B[0m)" : ""}');
    } else {
      failed++;
      print('  \x1B[31m✖ [FAIL]\x1B[0m $name ${extra != null ? "(\x1B[31m$extra\x1B[0m)" : ""}');
    }
  }

  try {
    print('\x1B[33m[1] PUBLIC & CONFIGURATION\x1B[0m');
    final terms = await req(method: 'GET', path: '/legal/terms');
    check('GET /legal/terms', terms['status'] == 200 && terms['body']?['success'] == true);

    final faq = await req(method: 'GET', path: '/support/faq');
    check('GET /support/faq', faq['status'] == 200 && (faq['body']?['data'] as List).isNotEmpty);

    print('\n\x1B[33m[2] AUTH & TOKEN ROTATION\x1B[0m');
    final reg = await req(method: 'POST', path: '/auth/register', body: {
      'phoneNumber': phone,
      'fullName': 'Nguyen Van Probe',
      'password': 'Password123!',
      'deviceId': 'probe-dev',
    });
    check('POST /auth/register', reg['status'] == 201 && reg['body']?['success'] == true);

    final token = reg['body']?['data']?['accessToken'] as String?;
    final refreshToken = reg['body']?['data']?['refreshToken'] as String?;

    final login = await req(method: 'POST', path: '/auth/login', body: {
      'phoneNumber': phone,
      'password': 'Password123!',
      'deviceId': 'probe-dev',
    });
    check('POST /auth/login', login['status'] == 200 && login['body']?['success'] == true);
    final freshRefresh = login['body']?['data']?['refreshToken'] as String? ?? refreshToken;

    final refresh = await req(method: 'POST', path: '/auth/refresh', query: {'refreshToken': freshRefresh!});
    check('POST /auth/refresh', refresh['status'] == 200 && refresh['body']?['success'] == true);

    final activeToken = refresh['body']?['data']?['accessToken'] as String? ?? token;

    print('\n\x1B[33m[3] PROFILE, PIN & SECURITY\x1B[0m');
    final profile = await req(method: 'GET', path: '/users/me', token: activeToken);
    check('GET /users/me', profile['status'] == 200 && profile['body']?['data']?['fullName'] == 'Nguyen Van Probe');

    final setPin = await req(method: 'POST', path: '/users/pin/set', body: {'pin': '654321'}, token: activeToken);
    check('POST /users/pin/set', setPin['status'] == 200);

    final verifyPin = await req(method: 'POST', path: '/users/pin/verify', body: {'pin': '654321'}, token: activeToken);
    final pinToken = verifyPin['body']?['data'] as String?;
    check('POST /users/pin/verify', verifyPin['status'] == 200 && pinToken != null);

    final limits = await req(method: 'GET', path: '/config/limits/status', token: activeToken);
    check('GET /config/limits/status', limits['status'] == 200 && limits['body']?['data']?['dailyLimit'] != null);

    print('\n\x1B[33m[4] WALLET & DEPOSIT\x1B[0m');
    final recipInfo = await req(method: 'GET', path: '/wallets/recipient-info', query: {'phoneNumber': phone}, token: activeToken);
    final walletId = recipInfo['body']?['data']?['walletId'] as String?;
    check('GET /wallets/recipient-info', recipInfo['status'] == 200 && walletId != null, 'walletId: $walletId');

    final wallet = await req(method: 'GET', path: '/wallets/$walletId', token: activeToken);
    check('GET /wallets/{id}', wallet['status'] == 200, 'Balance: ${wallet['body']?['data']?['balance']} VND');

    final deposit = await req(
      method: 'POST',
      path: '/wallets/deposit',
      headers: {'Idempotency-Key': 'dep-$ts'},
      body: {'requestId': 'req-dep-$ts', 'walletId': walletId, 'amount': 1500000.0, 'currency': 'VND'},
      token: activeToken,
    );
    check('POST /wallets/deposit', deposit['status'] == 200);

    final fee = await req(
      method: 'GET',
      path: '/wallets/fees/estimate',
      query: {'type': 'TRANSFER', 'amount': '200000', 'currency': 'VND'},
      token: activeToken,
    );
    check('GET /wallets/fees/estimate', fee['status'] == 200 && fee['body']?['data']?['feeAmount'] == 0);

    print('\n\x1B[33m[5] P2P MONEY TRANSFER\x1B[0m');
    final regRec = await req(method: 'POST', path: '/auth/register', body: {
      'phoneNumber': receiverPhone,
      'fullName': 'Tran Thi Recipient',
      'password': 'Password123!',
      'deviceId': 'rec-dev',
    });
    final recWalletId = (await req(method: 'GET', path: '/wallets/recipient-info', query: {'phoneNumber': receiverPhone}, token: activeToken))['body']?['data']?['walletId'] as String?;

    final initTx = await req(
      method: 'POST',
      path: '/wallets/transfer/init',
      headers: {'Idempotency-Key': 'tx-init-$ts'},
      body: {
        'requestId': 'req-tx-$ts',
        'sourceWalletId': walletId,
        'targetWalletId': recWalletId,
        'amount': 100000.0,
        'currency': 'VND',
        'bankCode': 'SENHONG',
        'note': 'Test transfer probe',
      },
      token: activeToken,
    );
    final txId = initTx['body']?['data']?['transactionId'] as String?;
    check('POST /wallets/transfer/init', initTx['status'] == 200 && txId != null, 'TxId: $txId');

    final confirmTx = await req(
      method: 'POST',
      path: '/wallets/transfer/$txId/confirm',
      query: {'pin': '654321'},
      token: activeToken,
    );
    check('POST /wallets/transfer/{id}/confirm', confirmTx['status'] == 200 && confirmTx['body']?['data']?['status'] == 'SUCCESS');

    print('\n\x1B[33m[6] TRANSACTIONS, STATEMENTS & PDF RECEIPT\x1B[0m');
    final txList = await req(method: 'GET', path: '/transactions', query: {'walletId': walletId!}, token: activeToken);
    check('GET /transactions', txList['status'] == 200 && (txList['body']?['data'] as List).isNotEmpty);

    final txDetail = await req(method: 'GET', path: '/transactions/$txId', token: activeToken);
    check('GET /transactions/{id}', txDetail['status'] == 200);

    final receiptPdf = await req(method: 'GET', path: '/transactions/$txId/receipt.pdf', token: activeToken);
    final isPdf = receiptPdf['status'] == 200 && (receiptPdf['bytes'] as List<int>).length > 50;
    check('GET /transactions/{id}/receipt.pdf', isPdf, 'Binary PDF Stream');

    final csvExport = await req(method: 'GET', path: '/transactions/export/csv', query: {'walletId': walletId}, token: activeToken);
    check('GET /transactions/export/csv', csvExport['status'] == 200, 'CSV Stream');

    print('\n\x1B[33m[7] BANKING, BENEFICIARIES & WITHDRAWAL\x1B[0m');
    final banks = await req(method: 'GET', path: '/banks', token: activeToken);
    check('GET /banks', banks['status'] == 200 && (banks['body']?['data'] as List).length >= 4);

    final linkBank = await req(
      method: 'POST',
      path: '/bank-accounts/link',
      body: {'bankCode': 'VCB', 'accountNumber': '001100998877', 'accountHolderName': 'NGUYEN VAN PROBE'},
      token: activeToken,
    );
    final bankAccId = linkBank['body']?['data']?['id'] as String?;
    check('POST /bank-accounts/link', linkBank['status'] == 201 && bankAccId != null);

    final bankAccounts = await req(method: 'GET', path: '/bank-accounts', token: activeToken);
    check('GET /bank-accounts', bankAccounts['status'] == 200 && (bankAccounts['body']?['data'] as List).isNotEmpty);

    final addBen = await req(
      method: 'POST',
      path: '/beneficiaries',
      body: {'nickname': 'Ban than', 'bankCode': 'SENHONG', 'accountNumber': receiverPhone, 'beneficiaryWalletId': recWalletId},
      token: activeToken,
    );
    check('POST /beneficiaries', addBen['status'] == 201);

    final withdraw = await req(
      method: 'POST',
      path: '/wallets/withdraw',
      headers: {'Idempotency-Key': 'with-$ts'},
      body: {'requestId': 'req-with-$ts', 'walletId': walletId, 'bankAccountId': bankAccId, 'amount': 20000.0, 'currency': 'VND', 'pinToken': pinToken},
      token: activeToken,
    );
    check('POST /wallets/withdraw', withdraw['status'] == 200 && withdraw['body']?['data']?['status'] == 'SUCCESS');

    print('\n\x1B[33m[8] BILLS & VIETQR\x1B[0m');
    final billLookup = await req(method: 'GET', path: '/bills/lookup', query: {'type': 'ELECTRICITY', 'customerCode': 'EVN123456'}, token: activeToken);
    check('GET /bills/lookup', billLookup['status'] == 200);

    final vietQr = await req(
      method: 'POST',
      path: '/payments/vietqr/generate',
      body: {'bankBin': '970436', 'accountNumber': '001100998877', 'amount': 300000, 'purpose': 'Thanh toan sach'},
      token: activeToken,
    );
    final qrString = vietQr['body']?['data']?['qrCodeString'] as String?;
    check('POST /payments/vietqr/generate', vietQr['status'] == 200 && qrString != null);

    final decodeQr = await req(method: 'POST', path: '/payments/vietqr/decode', query: {'qrString': qrString!}, token: activeToken);
    check('POST /payments/vietqr/decode', decodeQr['status'] == 200 && decodeQr['body']?['data']?['qrCodeString'] == qrString);

    print('\n\x1B[33m[9] NOTIFICATIONS & TICKETS\x1B[0m');
    final notifs = await req(method: 'GET', path: '/notifications', token: activeToken);
    check('GET /notifications', notifs['status'] == 200 && notifs['body']?['data']?['content'] != null);

    final readAll = await req(method: 'PATCH', path: '/notifications/read-all', token: activeToken);
    check('PATCH /notifications/read-all', readAll['status'] == 200);

    final ticket = await req(
      method: 'POST',
      path: '/support/tickets',
      query: {'subject': 'Probe Ticket', 'category': 'GENERAL', 'initialMessage': 'CLI probe ticket'},
      token: activeToken,
    );
    check('POST /support/tickets', ticket['status'] == 201);
  } catch (e, st) {
    print('\x1B[31mError during execution: $e\n$st\x1B[0m');
  } finally {
    client.close();
  }

  print('\n\x1B[36m=================================================================\x1B[0m');
  print('  TOTAL CHECKS : ${passed + failed}');
  print('  \x1B[32mPASSED       : $passed\x1B[0m');
  print('  \x1B[31mFAILED       : $failed\x1B[0m');
  print('\x1B[36m=================================================================\x1B[0m');
}
