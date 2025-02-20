import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(
      String uid, String phoneNumber, String name, String password) async {
    print(
        "name..............................................................: $name");
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

  Future<bool> doesPhoneNumberExist(String phoneNumber) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      print("is phone number exist: ${query.docs.isNotEmpty}");
      return query.docs.isNotEmpty;
    } catch (e) {
      print("Error checking phone number: $e");
      return false;
    }
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
      print("User data deleted for uid: $uid");
    } catch (e) {
      print("Error deleting user data: $e");
    }
  }

  Future<void> updateUserPin(String uid, String pin) async {
    try {
      await usersCollection.doc(uid).update({
        'password': pin,
      });
      print("User PIN updated for uid: $uid");
    } catch (e) {
      print("Error updating user PIN: $e");
    }
  }
}
