import 'package:flutter/material.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/snakebar.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _setPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isNewPinVisible = false;
  bool _isConfirmPinVisible = false;

  void _submitPin() async {
    if (_formKey.currentState!.validate()) {
      if (_setPinController.text == _confirmPinController.text) {
        User? user = _auth.currentUser;
        if (user != null) {
          await _userService.updateUserPin(
            user.uid,
            _setPinController.text,
          );

          // Navigate to Home or Dashboard with animation
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
                  Duration(milliseconds: 500), // Adjust duration as needed
            ),
          );
        } else {
          CustomSnackBar.show(context, 'User not logged in.', Colors.red);
        }
      } else {
        CustomSnackBar.show(
            context, 'PINs do not match. Try again.', Colors.red);
      }
    }
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
                  SizedBox(height: 50),
                  Text(
                    'SET PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'EzraSemiBold',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _setPinController,
                          labelText: 'New PIN',
                          keyboardType: TextInputType.number,
                          obscureText: !_isNewPinVisible,
                          prefixIcon: Icons.lock_open,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPinVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPinVisible = !_isNewPinVisible;
                              });
                            },
                          ),
                          maxLength: 4,
                          counterText: '',
                          validator: (value) {
                            if (value == null || value.length != 4) {
                              return 'Enter a 4-digit PIN';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: _confirmPinController,
                          labelText: 'Confirm PIN',
                          keyboardType: TextInputType.number,
                          obscureText: !_isConfirmPinVisible,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPinVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPinVisible = !_isConfirmPinVisible;
                              });
                            },
                          ),
                          maxLength: 4,
                          counterText: '',
                          validator: (value) {
                            if (value == null || value.length != 4) {
                              return 'Enter a 4-digit PIN';
                            } else if (value != _setPinController.text) {
                              return 'PINs do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context)
                                .unfocus(); // Dismiss the keyboard
                            _submitPin();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 100, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          child: const Text(
                            'Set PIN',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
