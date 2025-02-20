import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:password_manager/services/auth_service.dart';
import 'package:flutter/services.dart';

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

  void _deletePassword(String docId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .doc(docId)
          .delete();
      _fetchPasswords();
    }
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Password'),
          content: Text('Are you sure you want to delete this password?'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePassword(docId);
              },
            ),
          ],
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
            child: BackButton(
              color: Colors.white,
              onPressed: () {
                print('Back Button Pressed');
                Navigator.of(context).pop();
              },
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
                    'assets/images/pass.png', // Update with your image path
                    width: 250,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Platform',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterPasswords,
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : filteredPasswords.isEmpty
                            ? Card(
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
                                          Icons.add,
                                          size: 50,
                                          color: Colors.blueGrey.shade900,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Please Add Passwords',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredPasswords.length,
                                itemBuilder: (context, index) {
                                  DocumentSnapshot doc =
                                      filteredPasswords[index];
                                  bool isVisible =
                                      passwordVisibility[doc.id] ?? false;
                                  return Card(
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
                                        borderRadius: BorderRadius.circular(20),
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
                                              onPressed: () => _copyToClipboard(
                                                  doc['password']),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _showDeleteConfirmationDialog(
                                                      doc.id),
                                            ),
                                          ],
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
