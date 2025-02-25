import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/navigationScreen.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController currentPinController = TextEditingController();
  final TextEditingController newPinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  bool _isCurrentPinVisible = false;
  bool _isNewPinVisible = false;
  bool _isConfirmPinVisible = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  String userName = 'User Name';
  String phoneNumber = 'Phone Number';
  bool isLoading = true;
  bool isChangingPassword = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _fetchUserData();
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

  void _fetchUserData() async {
    try {
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        setState(() {
          userName = userDoc['name'] ?? 'User Name';
          phoneNumber = userDoc['phone_number'] ?? 'Phone Number';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  // void _showLogoutConfirmationDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Logout'),
  //         content: Text('Are you sure you want to logout?'),
  //         actions: [
  //           TextButton(
  //             child: Text('Cancel', style: TextStyle(color: Colors.green)),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Logout', style: TextStyle(color: Colors.red)),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _logout();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showLogoutConfirmationDialog() async {
    await SoundUtil.playSound('sounds/alert.mp3');

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

  // void _changePassword() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       final TextEditingController currentPinController =
  //           TextEditingController();
  //       final TextEditingController newPinController = TextEditingController();
  //       final TextEditingController confirmPinController =
  //           TextEditingController();

  //       return AlertDialog(
  //         title: Text('Change Password'),
  //         content: Container(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextField(
  //                 controller: currentPinController,
  //                 decoration: InputDecoration(labelText: 'Current PIN'),
  //                 obscureText: true,
  //                 keyboardType: TextInputType.number,
  //               ),
  //               SizedBox(height: 20),
  //               TextField(
  //                 controller: newPinController,
  //                 decoration: InputDecoration(labelText: 'New PIN'),
  //                 obscureText: true,
  //                 keyboardType: TextInputType.number,
  //               ),
  //               SizedBox(height: 20),
  //               TextField(
  //                 controller: confirmPinController,
  //                 decoration: InputDecoration(labelText: 'Confirm PIN'),
  //                 obscureText: true,
  //                 keyboardType: TextInputType.number,
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             child: Text('Cancel', style: TextStyle(color: Colors.red)),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Change', style: TextStyle(color: Colors.green)),
  //             onPressed: () {
  //               // Implement change password functionality here
  //               String currentPin = currentPinController.text;
  //               String newPin = newPinController.text;
  //               String confirmPin = confirmPinController.text;

  //               if (newPin == confirmPin) {
  //                 // Update the PIN in the database
  //                 _updatePin(currentPin, newPin);
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                       content: Text('New PIN and Confirm PIN do not match')),
  //                 );
  //               }
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _resetDialogState() {
    setState(() {
      _isCurrentPinVisible = false;
      _isNewPinVisible = false;
      _isConfirmPinVisible = false;
      currentPinController.clear();
      newPinController.clear();
      confirmPinController.clear();
      isChangingPassword = false;
    });
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width * 0.9, // Full width
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.change_circle,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            CustomTextField(
                              controller: currentPinController,
                              labelText: 'Current PIN',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_isCurrentPinVisible,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isCurrentPinVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isCurrentPinVisible =
                                        !_isCurrentPinVisible;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current PIN';
                                } else if (value.length != 4) {
                                  return 'Enter a 4-digit PIN';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            CustomTextField(
                              controller: newPinController,
                              labelText: 'New PIN',
                              prefixIcon: Icons.lock_open,
                              obscureText: !_isNewPinVisible,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              counterText: '',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your new PIN';
                                } else if (value.length != 4) {
                                  return 'Enter a 4-digit PIN';
                                } else if (value == currentPinController.text) {
                                  return 'Same as the current PIN';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            CustomTextField(
                              controller: confirmPinController,
                              labelText: 'Confirm PIN',
                              prefixIcon: Icons.lock,
                              obscureText: !_isConfirmPinVisible,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              counterText: '',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new PIN';
                                } else if (value.length != 4) {
                                  return 'Enter a 4-digit PIN';
                                } else if (value != newPinController.text) {
                                  return 'PINs do not match';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  child: Text('Cancel',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _resetDialogState();
                                  },
                                ),
                                TextButton(
                                  child: Text('Change',
                                      style: TextStyle(color: Colors.green)),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      FocusScope.of(context).unfocus();
                                      String currentPin =
                                          currentPinController.text;
                                      String newPin = newPinController.text;
                                      String confirmPin =
                                          confirmPinController.text;

                                      if (newPin == confirmPin) {
                                        // Update the PIN in the database
                                        _updatePin(
                                            currentPin, newPin, setState);
                                      } else {
                                        CustomSnackBar.show(
                                          context,
                                          'New PIN and Confirm PIN do not match',
                                          Colors.red,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isChangingPassword)
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
              ]),
            );
          },
        );
      },
    ).then((_) {
      _resetDialogState();
    });
  }

  void _updatePin(String currentPin, String newPin, Function setState) async {
    setState(() {
      isChangingPassword = true;
    });
    // Implement the logic to update the PIN in the database
    // For example, you can verify the current PIN and then update it with the new PIN
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc['password'] == currentPin) {
        await _firestore
            .collection('users')
            .doc(user!.uid)
            .update({'password': newPin});
        Navigator.of(context).pop();
        CustomSnackBar.show(context, 'PIN updated successfully', Colors.yellow,
            textColor: Colors.black);
        Provider.of<NotificationsProvider>(context, listen: false)
            .addNotification('Password Changed',
                'Your password has been changed successfully.', 'update');
      } else {
        CustomSnackBar.show(context, 'Incorrect PIN.', Colors.red);
      }
    } catch (e) {
      CustomSnackBar.show(
          context, 'An error occurred. Please try again.', Colors.red);
    } finally {
      setState(() {
        isChangingPassword = false;
      });
    }
  }

  void _helpAndSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController suggestionController =
            TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9, // Full width
                padding: EdgeInsets.all(16),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Help & Support',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.help, color: Colors.white),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        '- About This App:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• This app is designed to help you manage your passwords securely.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• You can store, update, and retrieve your passwords with ease.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• The app ensures your data is encrypted and safe.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '- How to Use This App:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• Go to Home and click on "Generate Password".',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• Enter the website or app name for which you want to generate a password.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• Choose from multiple options to generate a password.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• Copy the generated password and don\'t forget to save it.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• To access saved passwords easily, go to Home and click on "View Password".',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• Search by web or app name to find and copy your password for use.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '- Admin Information:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• Name: Bharat Sirvi',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      Text(
                        '• Email: bharatsirvi2020@gmail.com',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      CustomTextField(
                        controller: suggestionController,
                        labelText: 'Your Suggestion',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        maxLines: 3,
                        style: TextStyle(
                            color: Colors.white, decorationThickness: 0),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Send',
                                style: TextStyle(color: Colors.green)),
                            onPressed: () {
                              String suggestion = suggestionController.text;
                              if (suggestion.isNotEmpty) {
                                _sendEmail("Suggestion", suggestion);
                                Navigator.of(context).pop();
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  'Please provide your suggestion',
                                  Colors.white,
                                  textColor: Colors.black,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sendEmail(String subject, String body) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bharatsirvi2020@gmail.com', // Replace with the admin email
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);

        Provider.of<NotificationsProvider>(context, listen: false)
            .addNotification("Thank you!",
                "Your ${subject} has been sent successfully.", "neutral");
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'An error occurred. Please try again.',
        Colors.red,
      );
    }
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController issueController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9, // Full width
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Report an Issue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.report_problem, color: Colors.white),
                        ],
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        controller: issueController,
                        labelText: 'Describe the issue',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        maxLines: 3,
                        style: TextStyle(
                            color: Colors.white, decorationThickness: 0),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Report',
                                style: TextStyle(color: Colors.green)),
                            onPressed: () {
                              String issue = issueController.text;
                              if (issue.isNotEmpty) {
                                // Implement the logic to handle the issue report
                                _sendEmail("Issue Report", issue);
                                Navigator.of(context).pop();
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  'Please describe the issue',
                                  Colors.white,
                                  textColor: Colors.black,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();

    super.dispose();
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
          // Content
          Center(
            child: isLoading
                ? _buildSkeletonLoading()
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        // Column(
                        //   mainAxisAlignment: MainAxisAlignment.start,
                        //   mainAxisSize: MainAxisSize.min,
                        //   children: [
                        //     Icon(Icons.account_circle,
                        //         size: 80, color: Colors.blue[100]),
                        //     Text(
                        //       'Account Details',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 24,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        SizedBox(height: 20),
                        _buildAnimatedCard(
                          child: _buildCard(
                            title: 'Name: $userName',
                            icon: Icons.person,
                            gradientColors: [
                              const Color.fromARGB(255, 0, 191, 255),
                              const Color.fromARGB(255, 0, 19, 128),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedCard(
                          child: _buildCard(
                            title: 'Phone: $phoneNumber',
                            icon: Icons.phone,
                            gradientColors: [
                              const Color.fromARGB(255, 34, 134, 139),
                              const Color.fromARGB(255, 50, 205, 50),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedCard(
                          child: _buildCard(
                            title: 'Change Password',
                            icon: Icons.lock,
                            gradientColors: [
                              const Color.fromARGB(255, 0, 128, 128),
                              const Color.fromARGB(255, 0, 255, 255),
                            ],
                            onTap: _changePassword,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedCard(
                          child: _buildCard(
                            title: 'Help and Support',
                            icon: Icons.help,
                            gradientColors: [
                              const Color.fromARGB(255, 255, 165, 0),
                              const Color.fromARGB(255, 255, 215, 0),
                            ],
                            onTap: _helpAndSupport,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedCard(
                          child: _buildCard(
                            title: 'Report an Issue',
                            icon: Icons.report_problem,
                            gradientColors: [
                              const Color.fromARGB(255, 255, 69, 0),
                              const Color.fromARGB(255, 255, 140, 0),
                            ],
                            onTap: _reportIssue,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedCard(
                          child: _buildCard(
                            title: 'Logout',
                            icon: Icons.logout,
                            gradientColors: [
                              const Color.fromARGB(255, 77, 2, 2),
                              const Color.fromARGB(255, 255, 84, 87),
                            ],
                            onTap: _showLogoutConfirmationDialog,
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

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.black.withValues(alpha: 0.5), // Dark base color
      highlightColor: Colors.black
          .withValues(alpha: 0.2), // Slightly lighter highlight color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Skeleton for Name Card
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
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
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  trailing: Icon(Icons.person, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Skeleton for Phone Card
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
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
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  trailing: Icon(Icons.phone, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Skeleton for Change Password Card
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
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
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  trailing: Icon(Icons.lock, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Skeleton for Help and Support Card
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
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
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  trailing: Icon(Icons.help, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Skeleton for Report an Issue Card
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
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
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  trailing: Icon(Icons.report_problem, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Skeleton for Logout Card
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
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
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  trailing: Icon(Icons.logout, color: Colors.grey[600]),
                ),
              ),
            ),
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          trailing: Icon(icon, color: Colors.white70),
          onTap: onTap,
        ),
      ),
    );
  }
}
