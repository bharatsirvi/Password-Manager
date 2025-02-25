import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecureStorageUtil {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save the encryption key locally
  static Future<void> saveEncryptionKeyLocally(String key) async {
    await _storage.write(key: 'encryptionKey', value: key);
  }

  // Retrieve the encryption key locally
  static Future<String?> getEncryptionKeyLocally() async {
    return await _storage.read(key: 'encryptionKey');
  }

  // Delete the encryption key locally
  static Future<void> deleteEncryptionKeyLocally() async {
    await _storage.delete(key: 'encryptionKey');
  }

  // Save the encryption key to Firestore
  static Future<void> saveEncryptionKeyToFirestore(String key) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'encryptionKey': key,
      }, SetOptions(merge: true));
    }
  }

  // Retrieve the encryption key from Firestore
  static Future<String?> getEncryptionKeyFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return doc['encryptionKey'];
    }
    return null;
  }
}
