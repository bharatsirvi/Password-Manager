import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/utills/snakebar.dart';

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  List<String> currentPin = ["", "", "", ""];
  TextEditingController pinOneController = TextEditingController();
  TextEditingController pinTwoController = TextEditingController();
  TextEditingController pinThreeController = TextEditingController();
  TextEditingController pinFourController = TextEditingController();

  void _verifyPin() async {
    setState(() => isLoading = true);

    String enteredPin = currentPin.join();
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

    setState(() => isLoading = false);
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/images/logobig.png',
                    height: 200,
                  ),
                  SizedBox(height: 50),
                  Text(
                    'Enter your 4-digit PIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPinField(pinOneController, 0),
                      _buildPinField(pinTwoController, 1),
                      _buildPinField(pinThreeController, 2),
                      _buildPinField(pinFourController, 3),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyPin,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      textStyle: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    child: Text('Verify'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logout,
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    );
  }

  Widget _buildPinField(TextEditingController controller, int index) {
    return Container(
      width: 50,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        obscureText: true,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              width: 2,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            currentPin[index] = value;
            if (index < 3) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
              _verifyPin();
            }
          }
        },
      ),
    );
  }
}
