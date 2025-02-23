import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  String currentPin = "";
  TextEditingController pinController = TextEditingController();
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());

  void _verifyPin() async {
    setState(() => isLoading = true);

    String enteredPin = currentPin;
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        String storedPassword = userDoc['password'];

        if (enteredPin == storedPassword) {
          setState(() => isLoading = false);
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  BottomNavigation(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration:
                  Duration(milliseconds: 300), // Adjust duration as needed
            ),
          );
        } else {
          // PIN is incorrect
          CustomSnackBar.show(
              context, 'Incorrect PIN. Please try again.', Colors.red);
        }
      } catch (e) {
        CustomSnackBar.show(
            context, 'An error occurred. Please try again.', Colors.red);
      }
    } else {
      CustomSnackBar.show(context, 'User not logged in.', Colors.red);
    }
    setState(() {
      isLoading = false;
      currentPin = "";
      pinController.clear();
    });
  }

  void _showLogoutConfirmationDialog() async {
    await SoundUtil.playSound('sounds/alert.mp3'); // Use the sound utility

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9, // Full width
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 59, 84, 105),
                      const Color.fromARGB(255, 2, 36, 76)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.logout, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text('Cancel',
                              style: TextStyle(color: Colors.green)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                          ),
                          child: Text('Logout',
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _logout();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background color
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 59, 84, 105),
                  const Color.fromARGB(255, 2, 36, 76)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/images/vaultix.png',
                    height: 200,
                  ),
                  SizedBox(height: 40),
                  Text(
                    'ENTER 4 DIGIT PIN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: PinCodeTextField(
                      autoFocus: true,
                      onChanged: (value) {
                        setState(() {
                          currentPin = value;
                        });
                      },
                      obscureText: true,
                      obscuringCharacter: '*',
                      appContext: context,
                      length: 4,
                      controller: pinController,
                      animationType: AnimationType.fade,
                      onCompleted: (value) {
                        FocusScope.of(context).unfocus(); //
                        _verifyPin();
                      },
                      enablePinAutofill: true,
                      textGradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color.fromARGB(255, 162, 255, 178),
                          const Color.fromARGB(255, 0, 255, 8),
                        ],
                      ),
                      blinkDuration: Duration(milliseconds: 200),
                      blinkWhenObscuring: true,
                      animationDuration: Duration(milliseconds: 300),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(5),
                        fieldHeight: 50,
                        fieldWidth: 50,
                        activeFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        activeColor: Colors.green,
                        selectedColor: Colors.white,
                        inactiveColor: Colors.grey,
                      ),
                      backgroundColor: Colors.transparent,
                      showCursor: true,
                      cursorColor: Colors.white,
                      cursorWidth: 1,
                      keyboardType: TextInputType.number,
                      keyboardAppearance: Brightness.dark,
                      autoDismissKeyboard: false,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
              child: TextButton(
                onPressed: _showLogoutConfirmationDialog,
                child:
                    Icon(Icons.logout_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function to create a fade and slide transition route
Route _createParallaxTransitionRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Slide from right to left
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var slideTween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var slideAnimation = animation.drive(slideTween);

      return SlideTransition(
        position: slideAnimation,
        child: child,
      );
    },
  );
}
