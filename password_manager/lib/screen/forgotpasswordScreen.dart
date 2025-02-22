import 'package:flutter/material.dart';
import 'package:password_manager/screen/resetpasswordScreen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:password_manager/utills/snakebar.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isOTPSent = false;
  bool isLoading = false;
  String otp = '';
  String verificationId = '';

  final AuthService _authService = AuthService();

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    String phone = "+91${phoneController.text.trim()}";

    _authService.sendOTP(
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
    setState(() => isLoading = true);
    var credential = await _authService.verifyOTP(
      verificationId: verificationId,
      otp: otp,
    );

    if (credential?.user != null) {
      // **OTP Verified, Navigate to Reset Password Screen**
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ResetPasswordScreen(),
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
    } else {
      CustomSnackBar.show(context, 'Invalid OTP', Colors.red);
    }

    setState(() => isLoading = false);
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
                    Text(
                      'Forgot Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
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
                      ElevatedButton(
                        onPressed: _sendOTP,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 100, vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Send OTP'),
                      ),
                    ] else ...[
                      Text(
                        'Enter the OTP sent to your mobile number',
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
                      ElevatedButton(
                        onPressed: _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Verify OTP'),
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
