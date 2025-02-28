import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/utills/internetConnect.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shimmer/shimmer.dart';

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool _isFetch = false;
  String currentPin = "";
  TextEditingController pinController = TextEditingController();
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  FocusNode _pinFocusNode = FocusNode();
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pinFocusNode.requestFocus(); // Request focus when the screen loads
  }

  void _verifyPin() async {
    setState(() {
      _isFetch = true;
    });
    String enteredPin = currentPin;
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        String storedPassword = userDoc['password'];

        if (enteredPin == storedPassword) {
          setState(() {
            _isFetch = false;
          });
          setState(() => isLoading = true);
          await Future.delayed(Duration(milliseconds: 500));
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
    setState(() {
      // isLoading = false;

      _isFetch = false;

      currentPin = "";
      pinController.clear();
    });
  }

  void _showLogoutConfirmationDialog() async {
    await SoundUtil.playSound('sounds/warn.mp3'); // Use the sound utility

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.logout, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text('Cancel',
                              style: TextStyle(color: Colors.green)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                          ),
                          child: Text('Logout',
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _logout();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    isLoading = false;
    pinController.dispose();
    _isFetch = false;
    _pinFocusNode.dispose();
    SoundUtil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildNextScreenSkeleton(_isConnected)
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
                SafeArea(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: SingleChildScrollView(
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
                            SizedBox(height: 40),
                            Text(
                              'ENTER 4 DIGIT PIN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 40),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: PinCodeTextField(
                                autoFocus:
                                    true, // Automatically focus the field
                                focusNode:
                                    _pinFocusNode, // Assign the FocusNode
                                onChanged: (value) {
                                  setState(() {
                                    currentPin = value;
                                  });
                                },
                                obscureText: true,
                                obscuringCharacter: '*',
                                appContext: context,
                                length: 4,
                                controller: pinController,
                                animationType: AnimationType.fade,
                                onCompleted: (value) {
                                  // FocusScope.of(context).unfocus(); //
                                  _verifyPin();
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
                                  fieldWidth: 50,
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
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _isFetch
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : SizedBox(),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 40),
                    child: TextButton(
                      onPressed: _showLogoutConfirmationDialog,
                      child: Icon(Icons.logout_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
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
    );
  }
}

Widget _buildNextScreenSkeleton(bool _isConnected) {
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
      ),
      if (!_isConnected)
        Positioned(
          top: 0,
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
