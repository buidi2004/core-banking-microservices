import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

class PemUtils {
  /// Chuyển đổi chuỗi PEM RSA Public Key (X.509 SubjectPublicKeyInfo) sang RSAPublicKey của PointyCastle
  static RSAPublicKey parseRsaPublicKey(String pemString) {
    final lines = pemString
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .trim();

    final bytes = base64Decode(lines);
    final asn1Parser = ASN1Parser(bytes);
    final topSequence = asn1Parser.nextObject() as ASN1Sequence;

    // SubjectPublicKeyInfo: SEQUENCE { AlgorithmIdentifier, BIT STRING }
    final bitString = topSequence.elements![1] as ASN1BitString;
    final publicKeyBytes = bitString.stringValues as Uint8List;

    // RSAPublicKey: SEQUENCE { modulus INTEGER, publicExponent INTEGER }
    final rsaParser = ASN1Parser(publicKeyBytes);
    final rsaSequence = rsaParser.nextObject() as ASN1Sequence;
    final modulusInt = rsaSequence.elements![0] as ASN1Integer;
    final exponentInt = rsaSequence.elements![1] as ASN1Integer;

    return RSAPublicKey(modulusInt.integer!, exponentInt.integer!);
  }
}
