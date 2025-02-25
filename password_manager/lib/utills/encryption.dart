import 'package:encrypt/encrypt.dart';

class EncryptionUtil {
  // Encrypt data using AES
  static String encryptPassword(String password, String encryptionKey) {
    // Convert the encryption key into a 32-byte key (required for AES-256)
    final key = Key.fromUtf8(_padKey(encryptionKey));

    // Initialize the encryption algorithm (AES)
    final encrypter = Encrypter(AES(key));

    // Generate a random IV (Initialization Vector)
    final iv = IV.fromLength(16);
    print(iv.bytes);

    // Encrypt the password
    final encrypted = encrypter.encrypt(password, iv: iv);

    // Return the encrypted data as a base64-encoded string along with the IV
    return '${iv.base64}:${encrypted.base64}';
  }

  // Decrypt data using AES
  static String decryptPassword(
      String encryptedPassword, String encryptionKey) {
    // Split the encrypted data to retrieve the IV and the encrypted password
    final parts = encryptedPassword.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }

    // Convert the encryption key into a 32-byte key
    final key = Key.fromUtf8(_padKey(encryptionKey));

    // Initialize the encryption algorithm (AES)
    final encrypter = Encrypter(AES(key));

    // Decode the base64-encoded IV and encrypted password
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    // Decrypt the password
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    // Return the decrypted password
    return decrypted;
  }

  // Helper method to pad the encryption key to 32 bytes (required for AES-256)
  static String _padKey(String key) {
    // AES-256 requires a 32-byte key
    if (key.length < 32) {
      // Pad the key with zeros if it's too short
      return key.padRight(32, '\0');
    } else if (key.length > 32) {
      // Truncate the key if it's too long
      return key.substring(0, 32);
    }
    return key;
  }
}
