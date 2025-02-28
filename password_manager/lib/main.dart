import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/provider/notificationProvider.dart';

import 'package:password_manager/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:password_manager/screen/generatepasswordScreen.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/loginScreen.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/screen/profileScreen.dart';
import 'package:password_manager/screen/setpinScreen.dart';
import 'package:password_manager/screen/signupScreen.dart';
import 'package:password_manager/screen/splashScreen.dart';
import 'package:password_manager/screen/viewpasswordScreen.dart';

import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // runApp(MyApp());
  print(
      "app started..........................................................................................................");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _wasPaused = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(
        'AppLifecycleState:...........................................................................main   hai ye  $state');

    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      print(
          "Navigating to SplashScreen .................................................");

      navigatorKey.currentState?.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration:
              Duration(milliseconds: 500), // Adjust duration as needed
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Password Manager',
      theme: ThemeData(
        fontFamily: 'Eczar-Regular',
        brightness: Brightness.dark, // Set dark mode
        primaryColor: Color(0xFF1E1E2E), // Dark Blue
        scaffoldBackgroundColor: Color(0xFF2C2C2C), // Deep Gray
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E2E), // Dark Blue
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF1E1E2E), // Dark Blue
          secondary: Color(0xFF00FF7F), // Neon Green
          background: Color(0xFF2C2C2C), // Deep Gray
          surface: Color(0xFF1E1E2E), // Dark Blue
          onPrimary: Colors.white, // Text color on primary
          onSecondary: Colors.black, // Text color on secondary
          onBackground: Colors.white, // Text color on background
          onSurface: Colors.white, // Text color on surface
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFF00FF7F), // Neon Green Buttons
          textTheme: ButtonTextTheme.primary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00FF7F), // Neon Green
            foregroundColor: Colors.black, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF3C3C3C), // Darker Gray for input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Color(0xFF00FF7F), // Neon Green
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 191, 191, 216), // Dark Blue
              width: 2,
            ),
          ),
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
      home: SplashScreen(),
      onGenerateRoute: generateRoute,
    );
  }
}
