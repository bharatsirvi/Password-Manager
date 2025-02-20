import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:password_manager/routes.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String verificationId = '';
  bool isOTPSent = false;
  bool isLoading = false;
  String otp = '';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // Send OTP
  void _sendOTP() {
    setState(() => isLoading = true);
    _authService.sendOTP(
      phoneNumber: '+91${phoneController.text.trim()}',
      onCodeSent: (verId) {
        setState(() {
          verificationId = verId;
          isOTPSent = true;
          isLoading = false;
        });
      },
      onError: (errorMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
        setState(() => isLoading = false);
      },
    );
  }

  // Verify OTP and Register
  void _verifyOTP() async {
    setState(() => isLoading = true);
    var credential = await _authService.verifyOTP(
      verificationId: verificationId,
      otp: otp,
    );

    if (credential?.user != null) {
      // Save User Data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Successful!')),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.setPin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP')),
      );
    }

    setState(() => isLoading = false);
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
                  SizedBox(height: 20),
                  SizedBox(height: 50),
                  if (!isOTPSent) ...[
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Enter Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Enter Mobile Number',
                        prefixText: '+91 ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _sendOTP,
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Send OTP'),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                          child: Text(
                            'Login',
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Verify & Register'),
                    ),
                  ],
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
    );
  }
}
