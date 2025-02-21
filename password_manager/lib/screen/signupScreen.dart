import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/loginScreen.dart';
import 'package:password_manager/utills/snakebar.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String verificationId = '';
  bool isOTPSent = false;
  bool isLoading = false;
  String otp = '';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // Send OTP
  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    print(
        "phone...............................: ${phoneController.text.trim()}");
    bool phoneExists = await _userService
        .doesPhoneNumberExist("+91${phoneController.text.trim()}");

    if (phoneExists) {
      CustomSnackBar.show(
          context, 'Phone number already exists. Please login.', Colors.red);
      setState(() => isLoading = false);
      return;
    }

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
        CustomSnackBar.show(context, errorMsg, Colors.red);
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

    if (credential != null && credential.user != null) {
      await _userService.saveUserData(
        credential.user!.uid,
        "+91${phoneController.text.trim()}",
        nameController.text.trim(),
        '', // Assuming you don't have a password at this stage
      );

      CustomSnackBar.show(
          context, 'Registration Successful!', Color(0xFF00FF7F));
      Navigator.pushReplacementNamed(context, AppRoutes.setPin);
    } else {
      CustomSnackBar.show(context, 'Invalid OTP', Colors.red);
    }

    setState(() => isLoading = false);
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
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
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Enter Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
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
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?"),
                          TextButton(
                            onPressed: _navigateToLogin,
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Verify & Register'),
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
