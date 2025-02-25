import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:password_manager/provider/notificationProvider.dart';

import 'package:password_manager/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:password_manager/screen/setpinScreen.dart';
import 'package:password_manager/screen/splashScreen.dart';

import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // runApp(MyApp());
  print(
      "app started..........................................................................................................");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
