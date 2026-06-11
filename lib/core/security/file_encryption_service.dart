import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class FileEncryptionResult {
  const FileEncryptionResult({
    required this.cipherBytes,
    required this.keyBase64,
    required this.nonceBase64,
    required this.macBase64,
  });

  final Uint8List cipherBytes;
  final String keyBase64;
  final String nonceBase64;
  final String macBase64;
}

class FileEncryptionService {
  FileEncryptionService() : _algorithm = AesGcm.with256bits();

  static const algorithmName = 'AES-256-GCM';

  final AesGcm _algorithm;

  Future<FileEncryptionResult> encrypt(Uint8List plainBytes) async {
    final secretKey = await _algorithm.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();
    final box = await _algorithm.encrypt(plainBytes, secretKey: secretKey);
    return FileEncryptionResult(
      cipherBytes: Uint8List.fromList(box.cipherText),
      keyBase64: base64Encode(secretKeyBytes),
      nonceBase64: base64Encode(box.nonce),
      macBase64: base64Encode(box.mac.bytes),
    );
  }

  Future<Uint8List> decrypt({
    required Uint8List cipherBytes,
    required String keyBase64,
    required String nonceBase64,
    required String macBase64,
  }) async {
    final secretKey = SecretKey(base64Decode(keyBase64));
    final box = SecretBox(
      cipherBytes,
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(macBase64)),
    );
    final plainBytes = await _algorithm.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(plainBytes);
  }
}
