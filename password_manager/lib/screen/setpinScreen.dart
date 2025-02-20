import 'package:flutter/material.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _submitPin() async {
    if (_formKey.currentState!.validate()) {
      if (_setPinController.text == _confirmPinController.text) {
        User? user = _auth.currentUser;
        if (user != null) {
          await _userService.updateUserPin(
            user.uid,
            _setPinController.text,
          );
          CustomSnackBar.show(context, 'PIN set successfully!', Colors.green);
          // Navigate to Home or Dashboard
          Navigator.pushNamed(context, AppRoutes.home);
        } else {
          CustomSnackBar.show(context, 'User not logged in.', Colors.red);
        }
      } else {
        CustomSnackBar.show(
            context, 'PINs do not match. Try again.', Colors.red);
      }
    }
  }

  void _deleteUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _userService.deleteUserData(user.uid);
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted due to no PIN set.')),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _deleteUser();
    super.dispose();
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
                    'SET PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 50),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _setPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: 'Set PIN',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length != 4) {
                              return 'Enter a 4-digit PIN';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: 'Confirm PIN',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length != 4) {
                              return 'Enter a 4-digit PIN';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _submitPin,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 100, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          child: const Text('Submit'),
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
