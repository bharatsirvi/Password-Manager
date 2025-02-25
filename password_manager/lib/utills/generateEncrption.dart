import 'dart:convert';
import 'dart:math';

class EncryptionKeyGenerator {
  // Generate a secure random encryption key
  static String generateEncryptionKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(keyBytes);
  }
}
