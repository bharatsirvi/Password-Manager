import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/signupScreen.dart';
import 'package:password_manager/utills/snakebar.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String verificationId = '';
  bool isOTPSent = false;
  bool isLoading = false;
  String otp = '';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // **Step 1: Verify Phone and Password**
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

  // **Step 2: Send OTP**
  void _sendOTP(String phoneNumber) {
    _authService.sendOTP(
      phoneNumber: phoneNumber,
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

  // **Step 3: Verify OTP**
  void _verifyOTP() async {
    setState(() => isLoading = true);
    var credential = await _authService.verifyOTP(
      verificationId: verificationId,
      otp: otp,
    );

    if (credential?.user != null) {
      // **Login Successful, Navigate to Home**

      Navigator.pushReplacementNamed(context, AppRoutes.navigation);
    } else {
      CustomSnackBar.show(context, 'Invalid OTP', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                      'assets/images/logobig.png',
                      height: 200,
                    ),
                    SizedBox(height: 20),
                    SizedBox(height: 50),
                    if (!isOTPSent) ...[
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Enter Mobile Number',
                          prefixText: '+91 ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Enter Pin',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your pin';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _verifyPhoneAndPassword,
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
                    ] else ...[
                      Text(
                        'Enter the OTP sent to your mobile number',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      OTPTextField(
                        length: 6,
                        otpFieldStyle: OtpFieldStyle(
                            borderColor: Colors.white,
                            focusBorderColor: Colors.green,
                            enabledBorderColor: Colors.white),
                        width: MediaQuery.of(context).size.width,
                        fieldWidth: 40,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                        textFieldAlignment: MainAxisAlignment.spaceAround,
                        fieldStyle: FieldStyle.box,
                        onCompleted: (code) {
                          setState(() => otp = code);
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Verify & Login'),
                      ),
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
    );
  }
}
