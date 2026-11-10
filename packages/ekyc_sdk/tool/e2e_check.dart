// E2E kiểm chứng contract liên ngôn ngữ:
// Dart SDK (pointycastle) mã hóa → ekyc-ai-service (Python cryptography) giải mã
// + chạy pipeline AI thật trên GPU (SCRFD + ArcFace + MiniFASNet).
//
// Chạy:  cd packages/ekyc_sdk && dart run tool/e2e_check.dart
import 'dart:convert';
import 'dart:io';

import 'package:ekyc_sdk/src/crypto/hybrid_crypto_client.dart';
import 'package:ekyc_sdk/src/crypto/pem_utils.dart';

const serverBase = 'http://localhost:8900';
const userId = 'a11ce000-0000-0000-0000-000000000001';

Future<void> main() async {
  // Public key của server (đồng bộ certs/ekyc_public.pem)
  final pem = File('../../backend/services/ekyc-ai-service/certs/ekyc_public.pem').readAsStringSync();
  final client = HybridCryptoClient(serverPublicKey: PemUtils.parseRsaPublicKey(pem));

  final http = HttpClient();
  Future<Map<String, dynamic>> call(String method, String path, [Map<String, dynamic>? body]) async {
    final req = await http.openUrl(method, Uri.parse('$serverBase$path'));
    req.headers.contentType = ContentType.json;
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return {'status': res.statusCode, 'body': jsonDecode(text) as Map<String, dynamic>};
  }

  var pass = true;

  // [1] Health
  final health = await call('GET', '/api/v1/ekyc/ai/health');
  print('[1] health    : ${health['status']} provider=${health['body']['provider']}');
  pass &= health['status'] == 200 && '${health['body']['provider']}'.contains('CUDA');

  // [2] Session
  final sess = await call('POST', '/api/v1/ekyc/ai/session', {'userId': userId});
  final sessionId = sess['body']['sessionId'] as String;
  final nonce = sess['body']['nonce'] as String;
  print('[2] session   : ${sess['status']} id=${sessionId.substring(0, 8)}…');

  // [3] Verify — Dart mã hóa, Python giải mã + AI
  final faceFile = File('../../backend/services/ekyc-ai-service/models/face_a.jpg');
  final faceBytes = faceFile.existsSync()
      ? faceFile.readAsBytesSync()
      : File('/tmp/ekyc_face_a.jpg').readAsBytesSync();
  final selfie = base64Encode(faceBytes);
  final chip = base64Encode(faceBytes);
  final envelope = client.encryptPayload(
    sessionId: sessionId,
    nonce: nonce,
    payload: {'selfie': selfie, 'chipPhoto': chip},
  );
  final sw = Stopwatch()..start();
  final ver = await call('POST', '/api/v1/ekyc/ai/verify', envelope);
  sw.stop();
  final fm = ver['body']['faceMatch'] as Map<String, dynamic>;
  final lv = ver['body']['liveness'] as Map<String, dynamic>;
  print('[3] verify    : ${ver['status']} decision=${ver['body']['decision']} '
      'sim=${fm['similarity']} is_live=${lv['is_live']} dart→python=${sw.elapsedMilliseconds}ms');
  // Ảnh tĩnh phải bị Passive Liveness chặn
  pass &= ver['status'] == 200 &&
      ver['body']['decision'] == 'REJECTED' &&
      fm['matched'] == true &&
      lv['is_live'] == false;

  // [4] Replay bị chặn
  final replay = await call('POST', '/api/v1/ekyc/ai/verify', envelope);
  print('[4] replay    : ${replay['status']} ${replay['body']['detail']}');
  pass &= replay['status'] == 401;

  print('\n===> ${pass ? "E2E DART↔PYTHON CONTRACT PASSED" : "E2E FAILED"}');
  http.close();
  exit(pass ? 0 : 1);
}
