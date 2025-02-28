import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/encryption.dart';
import 'package:password_manager/utills/internetConnect.dart';
import 'package:password_manager/utills/platform.dart';
import 'package:password_manager/utills/secure_storage.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:password_manager/utills/sound.dart';
import 'dart:math';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

class GeneratePasswordScreen extends StatefulWidget {
  @override
  _GeneratePasswordScreenState createState() => _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends State<GeneratePasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _platformController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _generatedPassword = '';
  int passwordLength = 12;
  bool includeUppercase = true;
  bool includeLowercase = true;
  bool includeNumbers = true;
  bool includeSymbols = true;
  bool _isLoading = false;
  bool _isVisible = false;

  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  AnimationController? _controller2;
  Animation<double>? _scaleAnimation2;

  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenForConnectivityChanges();
    // Initialize the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    // Define the shake animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize the second AnimationController
    _controller2 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    // Define the second shake animation
    _scaleAnimation2 = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller2!,
        curve: Curves.easeInOut,
      ),
    );

    // Define the shake animation

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeIn,
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller2?.dispose();
    _animationController?.dispose();
    SoundUtil.dispose();
    super.dispose();
  }

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

  String _generatePassword() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    Random random = Random.secure();
    return List.generate(
        passwordLength, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // void _savePassword() async {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }
  //   setState(() {
  //     isLoading = true;
  //   });

  //   String platform = platformController.text.trim().toLowerCase();

  //   if (generatedPassword.isEmpty) {
  //     CustomSnackBar.show(context, 'Please generate a password.', Colors.red);
  //     setState(() {
  //       isLoading = false;
  //     });
  //     return;
  //   }

  //   User? user = _auth.currentUser;
  //   if (user != null) {
  //     String encryptedPassword =
  //         await EncryptionUtil.encryptPassword(generatedPassword);
  //     QuerySnapshot snapshot = await _firestore
  //         .collection('users')
  //         .doc(user.uid)
  //         .collection('passwords')
  //         .where('platform', isEqualTo: platform)
  //         .get();

  //     if (snapshot.docs.isNotEmpty) {
  //       // Update the existing document
  //       await _firestore
  //           .collection('users')
  //           .doc(user.uid)
  //           .collection('passwords')
  //           .doc(snapshot.docs.first.id)
  //           .update({
  //         'password': encryptedPassword,
  //         'created_at': FieldValue.serverTimestamp(),
  //       });
  //       CustomSnackBar.show(
  //           context, 'Password updated successfully!', Colors.yellow,
  //           textColor: Colors.black);
  //       Provider.of<NotificationsProvider>(context, listen: false)
  //           .addNotification(
  //               'Password Updated', 'Password for $platform updated', 'update');
  //     } else {
  //       // Create a new document
  //       await _firestore
  //           .collection('users')
  //           .doc(user.uid)
  //           .collection('passwords')
  //           .add({
  //         'platform': platform,
  //         'password': encryptedPassword,
  //         'created_at': FieldValue.serverTimestamp(),
  //       });
  //       CustomSnackBar.show(
  //           context, 'Password saved successfully!', Color(0xFF00FF7F),
  //           textColor: Colors.black);
  //       Provider.of<NotificationsProvider>(context, listen: false)
  //           .addNotification(
  //               'Password Saved', 'Password for $platform saved', 'success');
  //     }

  //     platformController.clear();
  //   } else {
  //     CustomSnackBar.show(context, 'User not logged in.', Colors.red);
  //   }
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  void _savePassword(Function setState) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      print(
          'Saving password....................................................');
      _isLoading = true;
    });

    final platform = _platformController.text.trim().toLowerCase();

    if (_generatedPassword.isEmpty) {
      CustomSnackBar.show(context, 'Please generate a password.', Colors.red);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      CustomSnackBar.show(context, 'User not logged in.', Colors.red);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Retrieve the encryption key from secure storager
      String? encryptionKey = await SecureStorageUtil.getEncryptionKeyLocally();
      if (encryptionKey == null) {
        print(
            'Encryption key not found locally, fetching from Firestore...........................................................');
        encryptionKey = await SecureStorageUtil.getEncryptionKeyFromFirestore();
      }

      if (encryptionKey == null) {
        throw Exception('Encryption key not found');
      }
      print(
          'Encryption Key:................................................................ $encryptionKey');
      if (encryptionKey == null) {
        throw Exception('Encryption key not found');
      }

      // Encrypt the password using the encryption key
      final encryptedPassword =
          EncryptionUtil.encryptPassword(_generatedPassword, encryptionKey);

      print(
          'encrypted password:................................................................ $encryptedPassword');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .where('platform', isEqualTo: platform)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await SoundUtil.playSound('sounds/warn.mp3');
        // Show confirmation dialog
        bool confirmUpdate = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, setState) {
              return WillPopScope(
                  onWillPop: () async {
                    if ((await Vibration.hasVibrator()) ?? false) {
                      Vibration.vibrate(duration: 100);
                    }
                    _controller2?.forward().then((_) {
                      _controller2?.reverse(); // Scale back to normal
                    });

                    return false;
                  },
                  child: ScaleTransition(
                      scale: _scaleAnimation2!,
                      child: AlertDialog(
                        title: Text('Confirm Update'),
                        content: Text(
                            'A password for $platform already exists. Do you want to update it?'),
                        actions: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              label: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                shadowColor: Colors.transparent,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'Update',
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ),
                        ],
                      )));
            });
          },
        );
        if (confirmUpdate) {
          // Update existing document
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('passwords')
              .doc(snapshot.docs.first.id)
              .update({
            'password': encryptedPassword,
            'created_at': FieldValue.serverTimestamp(),
          });
          CustomSnackBar.show(
              context, 'Password updated successfully!', Colors.yellow,
              textColor: Colors.black);
        } else {
          setState(() {
            _isLoading = false;
            Navigator.of(context).pop();
          });

          return;
        }
      } else {
        // Create new document
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('passwords')
            .add({
          'platform': platform,
          'password': encryptedPassword,
          'created_at': FieldValue.serverTimestamp(),
        });
        CustomSnackBar.show(
            context, 'Password saved successfully!', Color(0xFF00FF7F),
            textColor: Colors.black);
      }

      Provider.of<NotificationsProvider>(context, listen: false)
          .addNotification(
        snapshot.docs.isNotEmpty ? 'Password Updated' : 'Password Saved',
        'Password for $platform ${snapshot.docs.isNotEmpty ? 'updated' : 'saved'}',
        snapshot.docs.isNotEmpty ? 'update' : 'success',
      );

      await SoundUtil.playSound('sounds/notification.mp3');

      Navigator.of(context).pop();

      _platformController.clear();
    } catch (e) {
      CustomSnackBar.show(context, 'Error saving password: $e', Colors.red);
    }
    setState(() {
      _isLoading = false;
      FocusScope.of(context).unfocus();
      _platformController.clear();

      _generatedPassword = '';
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
  }

  void _showGeneratedPasswordDialog(Function setState) {
    showDialog(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                if ((await Vibration.hasVibrator()) ?? false) {
                  Vibration.vibrate(duration: 100);
                }
                _controller?.forward().then((_) {
                  _controller?.reverse(); // Scale back to normal
                });

                return false;
              },
              child: ScaleTransition(
                scale: _scaleAnimation!,
                child: Dialog(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 12, 90, 153),
                                  const Color.fromARGB(255, 3, 33, 69),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Copy & ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Tenada',
                                          // fontWeight: FontWeight.bold,
                                          color: Color(0xFF00FF7F),
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Must',
                                        style: TextStyle(
                                          fontSize: 18,
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 5,
                                          fontFamily: 'Tenada',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow[700],
                                          // Highlight color for "Must"
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' Save',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Tenada',
                                          // fontWeight: FontWeight.bold,
                                          color: Color(0xFF00FF7F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _isVisible
                                            ? _generatedPassword
                                            : '•' * _generatedPassword.length,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isVisible = !_isVisible;
                                        });
                                      },
                                      icon: _isVisible
                                          ? Icon(
                                              Icons.visibility,
                                              color: Colors.white,
                                            )
                                          : Icon(Icons.visibility_off,
                                              color: Colors.white),
                                    )
                                  ],
                                ),

                                Divider(
                                  color: Colors.white,
                                  thickness: 1,
                                ),
                                SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                        ),
                                        label: Text(
                                          'Copy',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        icon: Icon(Icons.copy,
                                            color: Colors.white),
                                        onPressed: _copyToClipboard,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            'Save',
                                          ),
                                        ),
                                        onPressed: () {
                                          _savePassword(setState);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                //   ],
                                // ),
                              ],
                            )),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Warning: Unsaved changes will be lost.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            setState(() {
                              _isVisible = false;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      if (_isLoading)
                        Positioned.fill(
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
                    ])),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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

            Column(
              children: [
                SizedBox(height: 50),
                Image.asset(
                  'assets/images/generatePassword.png',
                  width: 300,
                ),
                SizedBox(height: 10),
                Text(
                  'HAM YAAD RAKHENGE',
                  style: TextStyle(
                    fontFamily: 'AspireNarrow',
                    fontSize: 12,
                    wordSpacing: 4,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700],
                  ),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: !_isConnected
                      ? _buildSkeletonLoading()
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildAnimatedCard(
                                    child: Card(
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color.fromARGB(
                                                  255, 1, 11, 23),
                                              const Color.fromARGB(
                                                  255, 16, 131, 224)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Autocomplete<String>(
                                              optionsBuilder: (TextEditingValue
                                                  textEditingValue) {
                                                if (textEditingValue
                                                    .text.isEmpty) {
                                                  return const Iterable<
                                                      String>.empty();
                                                }
                                                return platforms
                                                    .where((platform) {
                                                  return platform
                                                      .toLowerCase()
                                                      .startsWith(
                                                          textEditingValue.text
                                                              .toLowerCase());
                                                });
                                              },
                                              displayStringForOption:
                                                  (String option) => option,
                                              fieldViewBuilder:
                                                  (BuildContext context,
                                                      TextEditingController
                                                          textEditingController,
                                                      FocusNode focusNode,
                                                      VoidCallback
                                                          onFieldSubmitted) {
                                                _platformController.text =
                                                    textEditingController.text;
                                                return CustomTextField(
                                                  controller:
                                                      textEditingController,
                                                  autoFocus: false,
                                                  labelText:
                                                      'Enter Website/App Name',
                                                  autovalidate: true,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty ||
                                                        value == '') {
                                                      return 'Please enter a Website/App Name';
                                                    }
                                                    return null;
                                                  },
                                                  onTapOutside: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                  },
                                                  focusNode: focusNode,
                                                );
                                              },
                                              optionsViewBuilder: (BuildContext
                                                      context,
                                                  AutocompleteOnSelected<String>
                                                      onSelected,
                                                  Iterable<String> options) {
                                                return Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Material(
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.8,
                                                      child: ListView.builder(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        itemCount:
                                                            options.length,
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context,
                                                                int index) {
                                                          final String option =
                                                              options.elementAt(
                                                                  index);
                                                          return GestureDetector(
                                                            onTap: () {
                                                              onSelected(
                                                                  option);
                                                              FocusScope.of(
                                                                      context)
                                                                  .unfocus();
                                                            },
                                                            child: ListTile(
                                                              title:
                                                                  Text(option),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              onSelected: (String selection) {
                                                FocusScope.of(context)
                                                    .unfocus();

                                                setState(() {
                                                  _platformController.text =
                                                      selection;
                                                });
                                              },
                                            ),
                                            SizedBox(height: 20),
                                            Text(
                                              'Password Length: $passwordLength',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            Slider(
                                              // autofocus: true,

                                              value: passwordLength.toDouble(),
                                              min: 8,
                                              max: 20,

                                              label: passwordLength.toString(),
                                              activeColor: const Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255), // Set the active color
                                              inactiveColor: Colors.grey,
                                              onChanged: (double value) {
                                                setState(() {
                                                  passwordLength =
                                                      value.toInt();
                                                });
                                              },
                                            ),
                                            CheckboxListTile(
                                              title: Text('Include Uppercase'),
                                              value: includeUppercase,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  includeUppercase = value!;
                                                });
                                              },
                                            ),
                                            CheckboxListTile(
                                              title: Text('Include Lowercase'),
                                              value: includeLowercase,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  includeLowercase = value!;
                                                });
                                              },
                                            ),
                                            CheckboxListTile(
                                              title: Text('Include Numbers'),
                                              value: includeNumbers,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  includeNumbers = value!;
                                                });
                                              },
                                            ),
                                            CheckboxListTile(
                                              title: Text('Include Symbols'),
                                              value: includeSymbols,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  includeSymbols = value!;
                                                });
                                              },
                                            ),
                                            SizedBox(height: 20),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                FocusScope.of(context)
                                                    .unfocus(); //
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  setState(() {
                                                    _generatedPassword =
                                                        _generatePassword();
                                                    _isVisible = false;
                                                  });
                                                  _showGeneratedPasswordDialog(
                                                      setState);
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                }
                                              },
                                              icon: Icon(Icons.vpn_key),
                                              label: Text('Generate Password'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // SizedBox(height: 20),
                                  // if (_generatedPassword.isNotEmpty)
                                  //   Card(
                                  //     elevation: 10,
                                  //     shape: RoundedRectangleBorder(
                                  //       borderRadius: BorderRadius.circular(20),
                                  //     ),
                                  //     child: Container(
                                  //       decoration: BoxDecoration(
                                  //         gradient: LinearGradient(
                                  //           colors: [
                                  //             const Color.fromARGB(255, 4, 154, 9),
                                  //             const Color.fromARGB(255, 1, 138, 10)
                                  //           ],
                                  //           begin: Alignment.topLeft,
                                  //           end: Alignment.bottomRight,
                                  //         ),
                                  //         borderRadius: BorderRadius.circular(20),
                                  //       ),
                                  //       padding: const EdgeInsets.all(24.0),
                                  //       child: Column(
                                  //         mainAxisSize: MainAxisSize.min,
                                  //         children: [
                                  //           Text(
                                  //             'Copy & Click On Save',
                                  //             style: TextStyle(
                                  //                 fontSize: 16,
                                  //                 fontFamily: 'Tenada',
                                  //                 fontWeight: FontWeight.bold,
                                  //                 color: const Color.fromARGB(
                                  //                     255, 26, 27, 28)),
                                  //           ),
                                  //           SizedBox(height: 10),
                                  //           Row(
                                  //             mainAxisAlignment:
                                  //                 MainAxisAlignment.center,
                                  //             children: [
                                  //               Flexible(
                                  //                 child: Text(
                                  //                   _generatedPassword,
                                  //                   style: TextStyle(
                                  //                       fontSize: 16,
                                  //                       fontWeight: FontWeight.bold,
                                  //                       color: Colors.white),
                                  //                   overflow: TextOverflow.ellipsis,
                                  //                 ),
                                  //               ),
                                  //               IconButton(
                                  //                 icon: Icon(Icons.copy,
                                  //                     color: Colors.white),
                                  //                 onPressed: _copyToClipboard,
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ],
                                  //       ),
                                  //     ),
                                  //   ),
                                  // SizedBox(height: 20),
                                  // Align(
                                  //   alignment: Alignment.bottomCenter,
                                  //   child: _generatedPassword.isNotEmpty
                                  //       ? Container(
                                  //           margin: EdgeInsets.all(16.0),
                                  //           width: double.infinity,
                                  //           height: 60,
                                  //           decoration: BoxDecoration(
                                  //             gradient: LinearGradient(
                                  //               colors: [
                                  //                 const Color.fromARGB(
                                  //                     255, 0, 105, 191),
                                  //                 const Color.fromARGB(
                                  //                     255, 0, 119, 199),
                                  //               ],
                                  //               begin: Alignment.topLeft,
                                  //               end: Alignment.bottomRight,
                                  //             ),
                                  //             borderRadius: BorderRadius.circular(30),
                                  //           ),
                                  //           child: ElevatedButton(
                                  //             style: ElevatedButton.styleFrom(
                                  //               backgroundColor: Colors.transparent,
                                  //               shadowColor: Colors.transparent,
                                  //               shape: RoundedRectangleBorder(
                                  //                 borderRadius:
                                  //                     BorderRadius.circular(30),
                                  //               ),
                                  //             ),
                                  //             onPressed: _savePassword,
                                  //             child: Row(
                                  //               mainAxisAlignment:
                                  //                   MainAxisAlignment.center,
                                  //               children: [
                                  //                 Icon(
                                  //                   Icons.save,
                                  //                   color: Colors.white,
                                  //                 ),
                                  //                 SizedBox(width: 8),
                                  //                 Text(
                                  //                   'Save',
                                  //                   style: TextStyle(
                                  //                     color: Colors.white,
                                  //                     fontSize: 16,
                                  //                     fontWeight: FontWeight.bold,
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //           ),
                                  //         )
                                  //       : null,
                                  // ),
                                  // Add some space to avoid overlap with the button
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ), // ...existing code...
            Positioned(
              top: 40,
              left: 12,
              child: IconButton(
                icon: Icon(Icons.arrow_back),
                color: Colors.white,
                iconSize: 30,
                onPressed: () {
                  print("Back button pressed");
                  Navigator.of(context).pop();
                },
                tooltip: 'Back',
                splashColor: Colors.grey,
                highlightColor: Colors.black,
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
            // ...existing code...
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return FadeTransition(
      opacity: _animation!,
      child: child,
    );
  }
}

Widget _buildSkeletonLoading() {
  return Shimmer.fromColors(
    baseColor: Colors.black.withValues(alpha: 0.5), // Dark base color
    highlightColor: Colors.black
        .withValues(alpha: 0.2), // S/ Slightly lighter highlight color
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: 480,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[800]!,
                      Colors.grey[900]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24.0),
              ),
            )
            // SizedBox(height: 20),
            // if (_generatedPassword.isNotEmpty)
            //   Card(
            //     elevation: 10,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(20),
            //     ),
            //     child: Container(
            //       decoration: BoxDecoration(
            //         gradient: LinearGradient(
            //           colors: [
            //             const Color.fromARGB(255, 4, 154, 9),
            //             const Color.fromARGB(255, 1, 138, 10)
            //           ],
            //           begin: Alignment.topLeft,
            //           end: Alignment.bottomRight,
            //         ),
            //         borderRadius: BorderRadius.circular(20),
            //       ),
            //       padding: const EdgeInsets.all(24.0),
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text(
            //             'Copy & Click On Save',
            //             style: TextStyle(
            //                 fontSize: 16,
            //                 fontFamily: 'Tenada',
            //                 fontWeight: FontWeight.bold,
            //                 color: const Color.fromARGB(
            //                     255, 26, 27, 28)),
            //           ),
            //           SizedBox(height: 10),
            //           Row(
            //             mainAxisAlignment:
            //                 MainAxisAlignment.center,
            //             children: [
            //               Flexible(
            //                 child: Text(
            //                   _generatedPassword,
            //                   style: TextStyle(
            //                       fontSize: 16,
            //                       fontWeight: FontWeight.bold,
            //                       color: Colors.white),
            //                   overflow: TextOverflow.ellipsis,
            //                 ),
            //               ),
            //               IconButton(
            //                 icon: Icon(Icons.copy,
            //                     color: Colors.white),
            //                 onPressed: _copyToClipboard,
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // SizedBox(height: 20),
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: _generatedPassword.isNotEmpty
            //       ? Container(
            //           margin: EdgeInsets.all(16.0),
            //           width: double.infinity,
            //           height: 60,
            //           decoration: BoxDecoration(
            //             gradient: LinearGradient(
            //               colors: [
            //                 const Color.fromARGB(
            //                     255, 0, 105, 191),
            //                 const Color.fromARGB(
            //                     255, 0, 119, 199),
            //               ],
            //               begin: Alignment.topLeft,
            //               end: Alignment.bottomRight,
            //             ),
            //             borderRadius: BorderRadius.circular(30),
            //           ),
            //           child: ElevatedButton(
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: Colors.transparent,
            //               shadowColor: Colors.transparent,
            //               shape: RoundedRectangleBorder(
            //                 borderRadius:
            //                     BorderRadius.circular(30),
            //               ),
            //             ),
            //             onPressed: _savePassword,
            //             child: Row(
            //               mainAxisAlignment:
            //                   MainAxisAlignment.center,
            //               children: [
            //                 Icon(
            //                   Icons.save,
            //                   color: Colors.white,
            //                 ),
            //                 SizedBox(width: 8),
            //                 Text(
            //                   'Save',
            //                   style: TextStyle(
            //                     color: Colors.white,
            //                     fontSize: 16,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         )
            //       : null,
            // ),
            // Add some space to avoid overlap with the button
          ],
        ),
      ),
    ),
  );
}
