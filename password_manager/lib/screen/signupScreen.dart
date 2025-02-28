import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:password_manager/screen/loginScreen.dart';
import 'package:password_manager/screen/setpinScreen.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/internetConnect.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../services/auth_service.dart';

import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String verificationId = '';
  bool isOTPSent = false;
  bool isLoading = false;
  String otp = '';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Timer? _timer;
  int _start = 30;
  bool _isResendButtonEnabled = false;

  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  // Check initial connectivity status
  Future<void> _checkConnectivity() async {
    bool isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  // Listen for connectivity changes
  void _listenForConnectivityChanges() {
    _connectivityService.connectivityStream.listen((result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenForConnectivityChanges();
  }

  // Send OTP
  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

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
        setState(() => isLoading = false);
        setState(() {
          verificationId = verId;
          isOTPSent = true;
          isLoading = false;
          _startTimer();
        });
      },
      onError: (errorMsg) {
        print(
            "Error sending OTP:.................................................................................................................................... $errorMsg");
        setState(() => isLoading = false);
      },
    );
  }

  void _startTimer() {
    setState(() {
      _start = 30;
      _isResendButtonEnabled = false;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isResendButtonEnabled = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _resendOTP() {
    _sendOTP();
  }

  // Verify OTP and Register
  void _verifyOTP() async {
    setState(() => isLoading = true);
    var credential = await _authService.verifyOTP(
      verificationId: verificationId,
      otp: otp,
    );

    if (credential != null && credential.user != null) {
      print(
          "User ID:................................................................................. ${credential.user!.uid}");
      await _userService.saveUserData(
        credential.user!.uid,
        "+91${phoneController.text.trim()}",
        nameController.text.trim(),
        '', // Assuming you don't have a password at this stage
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SetPinScreen()),
      );
    } else {
      CustomSnackBar.show(context, 'Invalid OTP', Colors.red);
    }

    setState(() => isLoading = false);
  }

  void _navigateToLogin() {
    // Navigator.pushReplacement(
    //   context,
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       const begin = Offset(1.0, 0.0);
    //       const end = Offset.zero;
    //       const curve = Curves.ease;

    //       var tween =
    //           Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    //       return SlideTransition(
    //         position: animation.drive(tween),
    //         child: child,
    //       );
    //     },
    //   ),
    // );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isOTPSent && _start > 0) {
          return false; // Prevent back navigation if OTP timer is running
        }

        if (isOTPSent) {
          setState(() {
            isOTPSent = false;
            _timer?.cancel();
          });
          return false;
        }

        return true;
      },
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
                          controller: nameController,
                          labelText: 'Enter Name',
                          keyboardType: TextInputType.name,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z ]')),
                          ],
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: phoneController,
                          labelText: 'Enter Mobile Number',
                          keyboardType: TextInputType.phone,
                          hintText: 'e.g. 1234567890',
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
                        ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus(); //
                            _sendOTP();
                          },
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
                          'Enter the OTP sent to ${phoneController.text}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: PinCodeTextField(
                            autoFocus: true,
                            appContext: context,
                            controller: otpController,
                            length: 6,
                            animationType: AnimationType.fade,
                            onCompleted: (code) {
                              setState(() => otp = code);
                              FocusScope.of(context).unfocus(); //
                              _verifyOTP();
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

                        if (_start > 0)
                          Text(
                            'Resend OTP in $_start seconds',
                            style: TextStyle(color: Colors.white),
                          )
                        else
                          ElevatedButton(
                            onPressed:
                                _isResendButtonEnabled ? _resendOTP : null,
                            child: Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        // ElevatedButton(
                        //   onPressed: _verifyOTP,
                        //   style: ElevatedButton.styleFrom(
                        //     padding: EdgeInsets.symmetric(
                        //         horizontal: 50, vertical: 15),
                        //     textStyle: TextStyle(fontSize: 18),
                        //   ),
                        //   child: Text('Verify & Register'),
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
            if (!_isConnected)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  color: const Color.fromARGB(255, 88, 15, 10),
                  child: Text(
                    'No internet connection! please check your connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
