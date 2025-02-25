import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/generateEncrption.dart';
import 'package:password_manager/utills/secure_storage.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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

  bool isLoading = false;
  void _submitPin() async {
    if (_formKey.currentState!.validate()) {
      if (_setPinController.text == _confirmPinController.text) {
        setState(() {
          isLoading = true;
        });
        await Future.delayed(Duration(milliseconds: 1000));
        User? user = _auth.currentUser;
        if (user != null) {
          await _userService.updateUserPin(
            user.uid,
            _setPinController.text,
          );

          String encryptionKey = EncryptionKeyGenerator.generateEncryptionKey();
          await SecureStorageUtil.saveEncryptionKeyLocally(encryptionKey);
          await SecureStorageUtil.saveEncryptionKeyToFirestore(encryptionKey);
          await _clearNotifications();

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

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    await prefs.remove('notificationCount');

    Provider.of<NotificationsProvider>(context, listen: false)
        .clearNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildNextScreenSkeleton()
          : Stack(
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
                                      _isConfirmPinVisible =
                                          !_isConfirmPinVisible;
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

Widget _buildNextScreenSkeleton() {
  return Scaffold(
    appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
            const Color.fromARGB(255, 2, 36, 76), // Dark blue color
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/vaultixLogo.png', // Replace with your logo asset path
              height: 40,
            ),
            SizedBox(width: 5),
            Image.asset(
              'assets/images/vname4.png', // Replace with your logo asset path
              height: 25,
            ),
          ],
        ),
        actions: [
          NotificationIconWithBadge(),
          IconButton(icon: Icon(Icons.logout), onPressed: () {}),
        ]),
    body: Stack(children: [
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
      Center(
        child: Shimmer.fromColors(
          baseColor: Colors.black.withOpacity(0.5), // Dark base color
          highlightColor: Colors.black.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 200,
                  width: 300, // Set a fixed width for the card
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  width: 300, // Set a fixed width for the card
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    ]),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 2, 36, 76), // Dark blue color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, -1), // changes position of shadow
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors
            .transparent, // Make background transparent to show container color
        selectedItemColor: Colors.white, // Selected item color
        unselectedItemColor: Colors.grey, // Unselected item color
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    ),
  );
}
