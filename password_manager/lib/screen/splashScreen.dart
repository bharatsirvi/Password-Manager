// lib/screen/splashScreen.dart
import 'package:flutter/material.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/utills/authWrapper.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3), () {});
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/vaultixDark.jpg',
            fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      ),
    );
  }
}
