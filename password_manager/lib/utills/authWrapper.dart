import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/screen/pinScreen.dart';
import 'package:password_manager/screen/setpinScreen.dart';
import 'package:password_manager/screen/signupScreen.dart';

class AuthWrapper extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _checkIfPasswordExists(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    return userDoc.exists &&
        userDoc['password'] != null &&
        userDoc['password'].isNotEmpty &&
        userDoc['password'] != '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          User? user = snapshot.data;
          return FutureBuilder<bool>(
            future: _checkIfPasswordExists(user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                bool passwordExists = snapshot.data!;
                if (passwordExists) {
                  return PinScreen(); // Navigate to PinScreen if password exists
                } else {
                  return SetPinScreen(); // Navigate to SetPinScreen if password does not exist
                }
              } else {
                return RegisterScreen(); // Fallback to RegisterScreen if something goes wrong
              }
            },
          );
        } else {
          return RegisterScreen(); // Navigate to RegisterScreen if user is not logged in
        }
      },
    );
  }
}
