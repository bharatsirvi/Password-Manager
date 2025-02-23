import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/sound.dart';

class ViewPasswordsScreen extends StatefulWidget {
  @override
  _ViewPasswordsScreenState createState() => _ViewPasswordsScreenState();
}

class _ViewPasswordsScreenState extends State<ViewPasswordsScreen> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  List<DocumentSnapshot> passwords = [];
  List<DocumentSnapshot> filteredPasswords = [];
  Map<String, bool> passwordVisibility = {};
  bool isLoading = true;

  // Key for the AnimatedList
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _fetchPasswords();
  }

  void _fetchPasswords() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .get();
      setState(() {
        passwords = snapshot.docs;
        filteredPasswords = passwords;
        passwordVisibility = {
          for (var doc in passwords) doc.id: false,
        };
        isLoading = false;
      });
    }
  }

  void _filterPasswords(String query) {
    List<DocumentSnapshot> results = [];
    if (query.isEmpty) {
      results = passwords;
    } else {
      results = passwords
          .where((doc) =>
              doc['platform'].toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredPasswords = results;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _deletePassword(String docId, int index) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await SoundUtil.playSound('sounds/delete.mp3');
      // Remove the item from the list with animation
      final removedItem = filteredPasswords.removeAt(index);
      _animatedListKey.currentState!.removeItem(
        index,
        (context, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0), // Slide from right to left
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: Card(
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
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text(
                    removedItem['platform'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    passwordVisibility[removedItem.id] ?? false
                        ? removedItem['password']
                        : '•' * removedItem['password'].length,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          passwordVisibility[removedItem.id] ?? false
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordVisibility[removedItem.id] =
                                !(passwordVisibility[removedItem.id] ?? false);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            _copyToClipboard(removedItem['password']),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      // Delete the item from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .doc(docId)
          .delete();
    }
    setState(() {
      filteredPasswords = List.from(filteredPasswords);
    });
  }

  void _showDeleteConfirmationDialog(String docId, int index) async {
    await SoundUtil.playSound('sounds/alert.mp3');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
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
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Delete Password',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.delete, color: Colors.white),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Are you sure you want to delete this password?',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child:
                          Text('Cancel', style: TextStyle(color: Colors.green)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                      ),
                      child:
                          Text('Delete', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deletePassword(docId, index);
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
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/images/viewPassword.png', // Update with your image path
                    width: 180,
                  ),
                  SizedBox(height: 20),
                  CustomTextField(
                    controller: searchController,
                    labelText: 'Search by Website/App',
                    prefixIcon: Icons.search,
                    onChanged: _filterPasswords,
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : filteredPasswords.isEmpty
                            ? Card(
                                color: const Color.fromARGB(62, 6, 119, 211),
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  height: 200,
                                  padding: const EdgeInsets.all(24.0),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.password,
                                          size: 50,
                                          color: Colors.white30,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'No Passwords Found',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : AnimatedList(
                                key: _animatedListKey,
                                initialItemCount: filteredPasswords.length,
                                itemBuilder: (context, index, animation) {
                                  DocumentSnapshot doc =
                                      filteredPasswords[index];
                                  bool isVisible =
                                      passwordVisibility[doc.id] ?? false;
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(
                                          1, 0), // Slide from right to left
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
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
                                        padding: const EdgeInsets.all(16.0),
                                        child: ListTile(
                                          title: Text(
                                            doc['platform'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            isVisible
                                                ? doc['password']
                                                : '•' * doc['password'].length,
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  isVisible
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                  color: Colors.white70,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    passwordVisibility[doc.id] =
                                                        !isVisible;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.copy,
                                                  color: Colors.white70,
                                                ),
                                                onPressed: () =>
                                                    _copyToClipboard(
                                                        doc['password']),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    _showDeleteConfirmationDialog(
                                                        doc.id, index),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
