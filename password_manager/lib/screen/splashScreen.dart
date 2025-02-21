import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/utills/authWrapper.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _navigateToHome();
    _startFadeAnimation();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3), () {});
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => AuthWrapper()));
  }

  _startFadeAnimation() async {
    await Future.delayed(Duration(
        milliseconds: 500)); // Delay before starting the fade animation
    setState(() {
      _visible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                duration: Duration(seconds: 2),
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
                height: 10, // Add some space between the text and the slogan
              ),
              AnimatedTextKit(
                animatedTexts: [
                  ColorizeAnimatedText(
                    'Hame Yaad Hai',
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontFamily: 'GranicSlab',
                    ),
                    speed: Duration(milliseconds: 800),
                    colors: [
                      const Color.fromARGB(255, 255, 255, 153), // Light Yellow
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
    );
  }
}
