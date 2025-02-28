import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/screen/pinScreen.dart';
import 'package:password_manager/screen/setpinScreen.dart';
import 'package:password_manager/screen/signupScreen.dart';
import 'package:password_manager/utills/encryption.dart';
import 'package:password_manager/utills/generateEncrption.dart';
import 'package:password_manager/utills/internetConnect.dart';
import 'package:password_manager/utills/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenForConnectivityChanges();
    _startFadeAnimation();
    _loadNotificationsAndNavigate();
  }

  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  // Check initial connectivity status
  Future<void> _checkConnectivity() async {
    bool isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  // Listen for connectivity changes
  void _listenForConnectivityChanges() {
    _connectivityService.connectivityStream.listen((result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

// Usage

  Future<void> _loadNotificationsAndNavigate() async {
    await Future.delayed(Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final notificationsString = prefs.getString('notifications');
    List<Map<String, String>> notifications = [];
    int notificationCount = 0;

    if (notificationsString != null) {
      List<dynamic> decodedList = jsonDecode(notificationsString);
      notifications =
          decodedList.map((item) => Map<String, String>.from(item)).toList();
      notificationCount = prefs.getInt('notificationCount') ?? 0;
    }

    // Set notifications into the provider
    Provider.of<NotificationsProvider>(context, listen: false)
        .setNotifications(notifications, notificationCount);

    // Navigate to the next screen
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print(
          'User is already signed in............................................................................${user.phoneNumber}');
      bool passwordExists = await _checkIfPasswordExists(user.uid);
      if (passwordExists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PinScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SetPinScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen()),
      );
    }
  }

  Future<bool> _checkIfPasswordExists(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc.exists &&
          userDoc['password'] != null &&
          userDoc['password'].isNotEmpty;
    } catch (e) {
      print('Error checking if password exists: $e');
      return false;
    }
  }

  _startFadeAnimation() {
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _visible = true;
      });
    });
    // Delay before starting the fade animation
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 7, 57, 97),
                  const Color.fromARGB(255, 0, 8, 17)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _visible ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/vaultixLogo.png', // Path to your image file
                          width: 100,
                        ),
                        SizedBox(
                          height:
                              10, // Add some space between the image and the text
                        ),
                        Text('VAULTIX',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'EzraSemiBold',
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    height:
                        10, // Add some space between the text and the slogan
                  ),
                  AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'Hame Yaad Hai',
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontFamily: 'GranicSlab',
                        ),
                        speed: Duration(milliseconds: 500),
                        colors: [
                          const Color.fromARGB(
                              255, 255, 255, 153), // Light Yellow
                          const Color.fromARGB(255, 255, 255, 0), // Yellow
                          const Color.fromARGB(255, 255, 165, 0), // Orange
                          const Color.fromARGB(255, 99, 85, 0), // Gold
                        ],
                      ),
                    ],
                    isRepeatingAnimation: true,
                    repeatForever: true,
                  ),
                  SizedBox(
                    height:
                        20, // Add some space between the slogan and the Lottie animation
                  ),
                  Lottie.asset(
                    'assets/animations/splash_animation.json', // Path to your Lottie animation file
                    width: 300,
                  ),
                ],
              ),
            ),
          ),
          if (!_isConnected)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                color: const Color.fromARGB(255, 88, 15, 10),
                child: Text(
                  'No internet connection! please check your connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
