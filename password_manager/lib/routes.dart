// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/loginScreen.dart';
import 'package:password_manager/screen/setpinScreen.dart';
import 'package:password_manager/screen/signupScreen.dart';
import 'package:password_manager/screen/splashScreen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String setPin = '/setPin';
  static const String splash = '/splash';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => LoginScreen());
    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => RegisterScreen());
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => HomeScreen());
    case AppRoutes.setPin:
      return MaterialPageRoute(builder: (_) => SetPinScreen());
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => SplashScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}
