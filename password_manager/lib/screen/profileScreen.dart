import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  String userName = 'User Name';
  String phoneNumber = 'Phone Number';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _fetchUserData();
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

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
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
  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController currentPinController =
            TextEditingController();
        final TextEditingController newPinController = TextEditingController();
        final TextEditingController confirmPinController =
            TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // Full width
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
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
                          fontSize: 24,
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
                  TextField(
                    controller: currentPinController,
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: newPinController,
                    decoration: InputDecoration(
                      labelText: 'New PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_open),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: confirmPinController,
                    decoration: InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child:
                            Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Change',
                            style: TextStyle(color: Colors.green)),
                        onPressed: () {
                          String currentPin = currentPinController.text;
                          String newPin = newPinController.text;
                          String confirmPin = confirmPinController.text;

                          if (newPin == confirmPin) {
                            // Update the PIN in the database
                            _updatePin(currentPin, newPin);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'New PIN and Confirm PIN do not match')),
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
  }

  void _updatePin(String currentPin, String newPin) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current PIN is incorrect')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update PIN')),
      );
    }
  }

  void _helpAndSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController suggestionController =
            TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // Full width
            padding: EdgeInsets.all(16.0),
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
                          fontSize: 24,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.help, color: Colors.blueAccent),
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
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• You can store, update, and retrieve your passwords with ease.',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• The app ensures your data is encrypted and safe.',
                    style: TextStyle(fontSize: 12),
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
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• Email: bharatsirvi855@gmail.com',
                    style: TextStyle(fontSize: 12),
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
                    '• To add a new password, go to the "Add Password" section.',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• To view your passwords, go to the "View Passwords" section.',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• To update a password, select the password and choose "Edit".',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• To delete a password, select the password and choose "Delete".',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: suggestionController,
                    decoration: InputDecoration(
                      labelText: 'Your Suggestion',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child:
                            Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child:
                            Text('Send', style: TextStyle(color: Colors.green)),
                        onPressed: () {
                          String suggestion = suggestionController.text;
                          if (suggestion.isNotEmpty) {
                            // _sendEmail(suggestion);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Thank you for your suggestion!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Please enter a suggestion')),
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
  }

  void _sendEmail(String suggestion) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bharatsirvi855@gmail.com', // Replace with the admin email
      query:
          'subject=${Uri.encodeComponent('User Suggestion')}&body=${Uri.encodeComponent(suggestion)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send email')),
      );
    }
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
                ? CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_circle,
                                size: 80, color: Colors.blue[100]),
                            Text(
                              'Account Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  // Navy Blue
                                  const Color.fromARGB(
                                      255, 0, 191, 255) // Deep Sky Blue
                                  ,
                                  const Color.fromARGB(255, 0, 19, 128),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              title: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Name: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize:
                                            16, // Same font size as Change Password
                                      ),
                                    ),
                                    TextSpan(
                                      text: userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                        fontSize:
                                            16, // Same font size as Change Password
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing:
                                  Icon(Icons.person, color: Colors.white70),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(
                                      255, 34, 134, 139), // Forest Green
                                  const Color.fromARGB(
                                      255, 50, 205, 50) // Lime Green
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              title: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Phone: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize:
                                            16, // Same font size as Change Password
                                      ),
                                    ),
                                    TextSpan(
                                      text: phoneNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                        fontSize:
                                            16, // Same font size as Change Password
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing:
                                  Icon(Icons.phone, color: Colors.white70),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 0, 128, 128),
                                  const Color.fromARGB(255, 0, 255, 255)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              title: Text(
                                'Change Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16, // Ensure font size consistency
                                ),
                              ),
                              trailing: Icon(Icons.lock, color: Colors.white70),
                              onTap: _changePassword,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 255, 165, 0),
                                  const Color.fromARGB(255, 255, 215, 0)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              title: Text(
                                'Help and Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16, // Ensure font size consistency
                                ),
                              ),
                              trailing: Icon(Icons.help, color: Colors.white70),
                              onTap: _helpAndSupport,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 77, 2, 2),
                                  const Color.fromARGB(255, 255, 84, 87)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              title: Text(
                                'Logout',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16, // Ensure font size consistency
                                ),
                              ),
                              trailing:
                                  Icon(Icons.logout, color: Colors.white70),
                              onTap: _showLogoutConfirmationDialog,
                            ),
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
