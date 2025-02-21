import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/utills/platform.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'package:password_manager/services/auth_service.dart';
import 'dart:math';

class GeneratePasswordScreen extends StatefulWidget {
  @override
  _GeneratePasswordScreenState createState() => _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends State<GeneratePasswordScreen> {
  final TextEditingController platformController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String generatedPassword = '';

  String _generatePassword() {
    const length = 12;
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+';
    Random random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  void _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String platform = platformController.text.trim().toLowerCase();

    if (generatedPassword.isEmpty) {
      CustomSnackBar.show(context, 'Please generate a password.', Colors.red);
      return;
    }

    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .where('platform', isEqualTo: platform)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Update the existing document
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('passwords')
            .doc(snapshot.docs.first.id)
            .update({
          'password': generatedPassword,
          'created_at': FieldValue.serverTimestamp(),
        });
        CustomSnackBar.show(
            context, 'Password updated successfully!', Colors.green);
      } else {
        // Create a new document
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('passwords')
            .add({
          'platform': platform,
          'password': generatedPassword,
          'created_at': FieldValue.serverTimestamp(),
        });
        CustomSnackBar.show(
            context, 'Password saved successfully!', Colors.green);
      }

      platformController.clear();
      setState(() {
        generatedPassword = '';
      });
    } else {
      CustomSnackBar.show(context, 'User not logged in.', Colors.red);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: generatedPassword));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    Image.asset(
                      'assets/images/gpass.png',
                      height: 250,
                      width: 250,
                    ),
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 1, 11, 23),
                              const Color.fromARGB(255, 16, 131, 224)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Autocomplete<String>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return platforms.where((platform) {
                                  return platform.toLowerCase().startsWith(
                                      textEditingValue.text.toLowerCase());
                                });
                              },
                              displayStringForOption: (String option) => option,
                              fieldViewBuilder: (BuildContext context,
                                  TextEditingController textEditingController,
                                  FocusNode focusNode,
                                  VoidCallback onFieldSubmitted) {
                                platformController.text =
                                    textEditingController.text;
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Platform',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        value == '') {
                                      return 'Please enter a platform';
                                    }
                                    return null;
                                  },
                                );
                              },
                              optionsViewBuilder: (BuildContext context,
                                  AutocompleteOnSelected<String> onSelected,
                                  Iterable<String> options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      child: ListView.builder(
                                        padding: EdgeInsets.all(8.0),
                                        itemCount: options.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          final String option =
                                              options.elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              onSelected(option);
                                            },
                                            child: ListTile(
                                              title: Text(option),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSelected: (String selection) {
                                setState(() {
                                  platformController.text = selection;
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    generatedPassword = _generatePassword();
                                  });
                                }
                              },
                              icon: Icon(Icons.vpn_key),
                              label: Text('Generate Password'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (generatedPassword.isNotEmpty)
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 4, 154, 9),
                                const Color.fromARGB(255, 1, 138, 10)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Copy & Click On Save',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Tenada',
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 26, 27, 28)),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    generatedPassword,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, color: Colors.white),
                                    onPressed: _copyToClipboard,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 80),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: generatedPassword.isNotEmpty
                          ? Container(
                              margin: EdgeInsets.all(16.0),
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 0, 105, 191),
                                    const Color.fromARGB(255, 0, 119, 199),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _savePassword,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Add some space to avoid overlap with the button
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 12,
            child: BackButton(
              color: Colors.white,
              onPressed: () {
                print("Back button pressed");
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
