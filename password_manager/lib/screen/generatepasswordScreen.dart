import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/platform.dart';
import 'package:password_manager/utills/snakebar.dart';
import 'dart:math';

import 'package:provider/provider.dart';

class GeneratePasswordScreen extends StatefulWidget {
  @override
  _GeneratePasswordScreenState createState() => _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends State<GeneratePasswordScreen> {
  final TextEditingController platformController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String generatedPassword = '';
  int passwordLength = 12;
  bool includeUppercase = true;
  bool includeLowercase = true;
  bool includeNumbers = true;
  bool includeSymbols = true;
  bool isLoading = false;

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

  void _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
    });

    String platform = platformController.text.trim().toLowerCase();

    if (generatedPassword.isEmpty) {
      CustomSnackBar.show(context, 'Please generate a password.', Colors.red);
      setState(() {
        isLoading = false;
      });
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
            context, 'Password updated successfully!', Colors.yellow,
            textColor: Colors.black);
        Provider.of<NotificationsProvider>(context, listen: false)
            .addNotification(
                'Password Updated', 'Password for $platform updated', 'update');
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
            context, 'Password saved successfully!', Color(0xFF00FF7F),
            textColor: Colors.black);
        Provider.of<NotificationsProvider>(context, listen: false)
            .addNotification(
                'Password Saved', 'Password for $platform saved', 'success');
      }

      platformController.clear();
    } else {
      CustomSnackBar.show(context, 'User not logged in.', Colors.red);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: generatedPassword));
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
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

            // Content
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
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
                                          return platform
                                              .toLowerCase()
                                              .startsWith(textEditingValue.text
                                                  .toLowerCase());
                                        });
                                      },
                                      displayStringForOption: (String option) =>
                                          option,
                                      fieldViewBuilder: (BuildContext context,
                                          TextEditingController
                                              textEditingController,
                                          FocusNode focusNode,
                                          VoidCallback onFieldSubmitted) {
                                        platformController.text =
                                            textEditingController.text;
                                        return CustomTextField(
                                          controller: textEditingController,
                                          labelText: 'Enter Website/App Name',

                                          autovalidate: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty ||
                                                value == '') {
                                              return 'Please enter a Website/App Name';
                                            }
                                            return null;
                                          },
                                          focusNode:
                                              focusNode, // Pass the focusNode if needed
                                        );
                                      },
                                      optionsViewBuilder: (BuildContext context,
                                          AutocompleteOnSelected<String>
                                              onSelected,
                                          Iterable<String> options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8,
                                              child: ListView.builder(
                                                padding: EdgeInsets.all(8.0),
                                                itemCount: options.length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
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
                                        FocusScope.of(context).unfocus();

                                        setState(() {
                                          platformController.text = selection;
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
                                          passwordLength = value.toInt();
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
                                        FocusScope.of(context).unfocus(); //
                                        if (_formKey.currentState!.validate()) {
                                          setState(() {
                                            generatedPassword =
                                                _generatePassword();
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
                                            color: const Color.fromARGB(
                                                255, 26, 27, 28)),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              generatedPassword,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.copy,
                                                color: Colors.white),
                                            onPressed: _copyToClipboard,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(height: 20),
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
                                            const Color.fromARGB(
                                                255, 0, 105, 191),
                                            const Color.fromARGB(
                                                255, 0, 119, 199),
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
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        onPressed: _savePassword,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                ),
              ],
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            // ...existing code...
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
            // ...existing code...
          ],
        ),
      ),
    );
  }
}
