import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/signupScreen.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String verificationId = '';
  bool isOTPSent = false;
  bool isLoading = false;
  bool isForgotPassword = false;
  bool isPasswordReset = false;
  bool _isPinVisible = false;

  String otp = '';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  void _verifyPhoneAndPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    String phone = "+91${phoneController.text.trim()}";
    String password = passwordController.text.trim();

    VerificationResult result =
        await _authService.verifyPhonePassword(phone, password);

    if (result == VerificationResult.success) {
      "Phone number and password verified...................";
      print("Phone number and password verified...................");

      print("phone number and password verified...................");
      _sendOTP(phone);
    } else {
      String errorMessage;
      if (result == VerificationResult.userNotFound) {
        errorMessage = 'Phone number not found. Please register first.';
      } else if (result == VerificationResult.wrongPassword) {
        errorMessage = 'Incorrect password. Please try again.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }
      CustomSnackBar.show(context, errorMessage, Colors.red);
      setState(() => isLoading = false);
    }
  }

  void _sendOTP(String phoneNumber) {
    setState(() => isLoading = true);
    _authService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verId) {
        setState(() {
          print("OTP sent successfully");
          verificationId = verId;
          isOTPSent = true;
          isLoading = false;
        });
      },
      onError: (errorMsg) {
        print("Error sending OTP: $errorMsg");
        CustomSnackBar.show(context, errorMsg, Colors.red);
        setState(() => isLoading = false);
      },
    );
  }

  // **Step 3: Verify OTP**
  void _verifyOTP() async {
    setState(() => isLoading = true);
    UserCredential? credential = await _authService.verifyOTP(
      verificationId: verificationId,
      otp: otp,
    );
    User? user = credential?.user;
    if (user != null) {
      await _retrieveAndStoreEncryptionKey();
      await _overrideNotifications(user.uid);
      // **Login Successful, Navigate to Home**
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              BottomNavigation(),
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
    } else {
      CustomSnackBar.show(context, 'Invalid OTP', Colors.red);
    }

    setState(() => isLoading = false);
  }

  Future<void> _retrieveAndStoreEncryptionKey() async {
    try {
      String? encryptionKey =
          await SecureStorageUtil.getEncryptionKeyFromFirestore();
      if (encryptionKey != null) {
        await SecureStorageUtil.saveEncryptionKeyLocally(encryptionKey);
        print('Encryption key retrieved and stored locally.');
      } else {
        print('Encryption key not found in Firestore.');
      }
    } catch (e) {
      print('Error retrieving encryption key: $e');
    }
  }

  Future<void> _overrideNotifications(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('notifications')) {
          List<dynamic> decodedList = data['notifications'];
          List<Map<String, String>> notifications = decodedList
              .map((item) => Map<String, String>.from(item))
              .toList();
          int notificationCount = data['notificationCount'] ?? 0;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('notifications', jsonEncode(notifications));
          await prefs.setInt('notificationCount', notificationCount);

          Provider.of<NotificationsProvider>(context, listen: false)
              .setNotifications(notifications, notificationCount);
          print('Notifications overridden in SharedPreferences.');
        }
      }
    } catch (e) {
      print('Error overriding notifications: $e');
    }
  }

  void _resetPassword() async {
    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      CustomSnackBar.show(context, 'Please fill all fields', Colors.red);
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      CustomSnackBar.show(context, 'Pins do not match', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _userService.updateUserPin(
          user.uid,
          newPasswordController.text,
        );
        CustomSnackBar.show(
            context, 'Password reset successfully', Color(0xFF00FF7F),
            textColor: Colors.black);
        Navigator.pop(context); // Close the dialog
      } else {
        CustomSnackBar.show(context, 'User not logged in', Colors.red);
      }
    } catch (e) {
      CustomSnackBar.show(context, e.toString(), Colors.red);
    }

    setState(() => isLoading = false);
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showForgotPasswordCard() {
    showDialog(
      context: context,
      builder: (context) {
        return ForgotPasswordCard(authService: _authService);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: Scaffold(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 50),
                      Image.asset(
                        'assets/images/vaultix.png',
                        height: 200,
                      ),
                      SizedBox(height: 20),
                      SizedBox(height: 50),
                      if (!isOTPSent) ...[
                        CustomTextField(
                          controller: phoneController,
                          labelText: 'Enter Mobile Number',
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          counterText: '',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            } else if (!RegExp(r'^[6-9]\d{9}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: passwordController,
                          labelText: 'Enter Pin',
                          keyboardType: TextInputType.number,
                          counterText: '',
                          obscureText: !_isPinVisible,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPinVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPinVisible = !_isPinVisible;
                              });
                            },
                          ),
                          maxLength: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your pin';
                            } else if (value.length != 4) {
                              return 'Enter a 4-digit pin';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus(); //
                            _verifyPhoneAndPassword();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 100, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          child: Text('Login'),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                            ),
                            TextButton(
                              onPressed: _navigateToSignup,
                              child: Text(
                                'Register',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordCard,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Enter the OTP sent to ${phoneController.text}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: PinCodeTextField(
                            autoFocus: true,
                            appContext: context,
                            length: 6,
                            animationType: AnimationType.fade,
                            onCompleted: (code) {
                              setState(() => otp = code);
                              FocusScope.of(context).unfocus(); //
                              _verifyOTP();
                            },
                            enablePinAutofill: true,
                            // enableActiveFill: true,
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
                              fieldWidth: 40,
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
                        // ElevatedButton(
                        //   onPressed: _verifyOTP,
                        //   style: ElevatedButton.styleFrom(
                        //     padding: EdgeInsets.symmetric(
                        //         horizontal: 50, vertical: 15),
                        //     textStyle: TextStyle(fontSize: 18),
                        //   ),
                        //   child: Text('Verify & Login'),
                        // ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordCard extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswordCard({required this.authService});

  @override
  _ForgotPasswordCardState createState() => _ForgotPasswordCardState();
}

class _ForgotPasswordCardState extends State<ForgotPasswordCard> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String verificationId = '';
  bool isOTPSent = false;
  bool isLoading = false;
  bool isPasswordReset = false;
  bool _isNewPinVisible = false;
  bool _isConfirmPinVisible = false;
  final UserService _userService = UserService();

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    String phone = "+91${phoneController.text.trim()}";

    widget.authService.sendOTP(
      phoneNumber: phone,
      onCodeSent: (verId) {
        setState(() {
          verificationId = verId;
          isOTPSent = true;
          isLoading = false;
        });
      },
      onError: (errorMsg) {
        CustomSnackBar.show(context, errorMsg, Colors.red);
        setState(() => isLoading = false);
      },
    );
  }

  void _verifyOTP() async {
    if (otpController.text.isEmpty) {
      CustomSnackBar.show(context, 'Please enter the OTP', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    var credential = await widget.authService.verifyOTP(
      verificationId: verificationId,
      otp: otpController.text,
    );

    if (credential?.user != null) {
      setState(() {
        isOTPSent = false;
        isPasswordReset = true;
        isLoading = false;
      });
    } else {
      CustomSnackBar.show(context, 'Invalid OTP', Colors.red);
      setState(() => isLoading = false);
    }
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = widget.authService.getCurrentUser();
      if (user != null) {
        await _userService.updateUserPin(
          user.uid,
          newPasswordController.text,
        );
        CustomSnackBar.show(
            context, 'Password reset successfully', Color(0xFF00FF7F),
            textColor: Colors.black);
        FocusScope.of(context).unfocus();
        Navigator.pop(context);

        // Close the dialog
      } else {
        CustomSnackBar.show(context, 'User not logged in', Colors.red);
      }
    } catch (e) {
      CustomSnackBar.show(context, e.toString(), Colors.red);
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                isPasswordReset ? Icons.restore : Icons.lock,
                                color: Colors.red,
                                size: 30,
                              ),
                              SizedBox(height: 10),
                              Text(
                                isPasswordReset
                                    ? 'Reset Password'
                                    : 'Forgot Password',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        if (!isOTPSent && !isPasswordReset) ...[
                          CustomTextField(
                            controller: phoneController,
                            labelText: 'Enter Mobile Number',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10,
                            prefixIcon: Icons.phone,
                            counterText: '',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              } else if (!RegExp(r'^[6-9]\d{9}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _sendOTP();
                            },
                            child: Text('SEND OTP',
                                style: TextStyle(
                                  color: Color(0xFF00FF7F),
                                  fontSize: 18,
                                )),
                          ),
                        ] else if (isOTPSent) ...[
                          Center(
                              child: Text(
                                  'Enter the OTP sent to ${phoneController.text}')),
                          SizedBox(height: 20),
                          PinCodeTextField(
                            appContext: context,
                            length: 6, // Set the length to 6 for 6-digit OTP
                            onChanged: (value) {},
                            onCompleted: (value) {
                              otpController.text = value;
                              FocusScope.of(context).unfocus();
                              _verifyOTP();
                            },
                            autoFocus: true,
                            animationType: AnimationType.fade,
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
                              fieldHeight: 40,
                              fieldWidth: 35,
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
                          SizedBox(height: 20),
                        ] else if (isPasswordReset) ...[
                          CustomTextField(
                            controller: newPasswordController,
                            labelText: 'New Pin',
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
                            keyboardType: TextInputType.number,
                            obscureText: !_isNewPinVisible,
                            maxLength: 4,
                            counterText: '',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your new pin';
                              } else if (value.length != 4) {
                                return 'Enter a 4-digit pin';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          CustomTextField(
                            controller: confirmPasswordController,
                            labelText: 'Confirm Pin',
                            keyboardType: TextInputType.number,
                            obscureText: !_isConfirmPinVisible,
                            maxLength: 4,
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
                            counterText: '',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your pin';
                              } else if (value != newPasswordController.text) {
                                return 'Pins do not match';
                              } else if (value.length != 4) {
                                return 'Enter a 4-digit pin';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _resetPassword();
                            },
                            child: Text('RESET PIN',
                                style: TextStyle(
                                  color: Color(0xFF00FF7F),
                                  fontSize: 18,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {},
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
