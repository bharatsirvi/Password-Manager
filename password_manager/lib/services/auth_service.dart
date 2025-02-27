import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:password_manager/utills/snakebar.dart';

enum VerificationResult {
  userNotFound,
  wrongPassword,
  success,
  error,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VerificationResult> verifyPhonePassword(
      String phoneNumber, String password) async {
    try {
      print("phone: $phoneNumber, password: $password");

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return VerificationResult.userNotFound; // User not found
      }

      // Retrieve user data
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      String storedPassword = userDoc['password'];

      if (storedPassword != password) {
        return VerificationResult.wrongPassword; // Wrong password
      }
      return VerificationResult.success; // Credentials are correct
    } catch (e) {
      print("Error verifying phone and password: $e");
      return VerificationResult.error; // Errorcd occurred
    }
  }

  // Send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    print(
        "Sending OTP to............................................................. $phoneNumber");
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print(
              "Verification failed.............................................................${e.message}");

          onError(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          print(
              "Code sent to............................................................. $phoneNumber");
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print(
              "Auto retrieval timeout...............................................");
        },
        timeout: Duration(seconds: 30),
      );
    } catch (e) {
      print(
          "Error sending OTP:......................................................................... ${e.toString()}");
      return onError("Error sending OTP");
    }
  }

  // Verify OTP
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
