import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(
      String uid, String phoneNumber, String name, String password) async {
    return await usersCollection.doc(uid).set({
      'uid': uid,
      'phone_number': phoneNumber,
      'name': name,
      'password': password,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> verifyPassword(
      String phoneNumber, String enteredPassword) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      var userDoc = query.docs.first;
      String storedPassword = userDoc['password'];
      print("Stored Password: $storedPassword");
      return storedPassword == enteredPassword;
    } catch (e) {
      print("Error verifying password: $e");
      return false;
    }
  }
}
