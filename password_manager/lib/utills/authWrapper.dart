import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:password_manager/screen/pinScreen.dart';
import 'package:password_manager/screen/loginScreen.dart';
import 'package:password_manager/screen/signupScreen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return PinScreen(); // Navigate to PinScreen if user is logged in
        } else {
          return RegisterScreen(); // Navigate to LoginScreen if user is not logged in
        }
      },
    );
  }
}
