import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:password_manager/utills/biomatric.dart';
import 'package:password_manager/utills/customTextField.dart';
import 'package:password_manager/utills/encryption.dart';
import 'package:password_manager/utills/internetConnect.dart';
import 'package:password_manager/utills/secure_storage.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

class ViewPasswordsScreen extends StatefulWidget {
  @override
  _ViewPasswordsScreenState createState() => _ViewPasswordsScreenState();
}

class _ViewPasswordsScreenState extends State<ViewPasswordsScreen>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final BiometricAuthUtil _biometricAuthUtil = BiometricAuthUtil();
  List<Map<String, dynamic>> passwords = []; // Store id, password, platform
  List<Map<String, dynamic>> filteredPasswords = [];
  Map<String, bool> passwordVisibility = {};
  bool isLoading = true;
  bool showCard = false;

  // Key for the AnimatedList
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();

  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _authenticateAndFetchPasswords();
    _checkConnectivity();
    _listenForConnectivityChanges();
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

  void _authenticateAndFetchPasswords() async {
    try {
      // Check if the device has any authentication method (PIN, Pattern, Password, or Biometrics)

      bool hasBiometric = await _biometricAuthUtil.canCheckBiometrics();
      bool isDeviceSupported = await _biometricAuthUtil.isDeviceSupported();
      bool hasBiometricOrPasscode = hasBiometric && isDeviceSupported;
      if (!hasBiometricOrPasscode) {
        print(
            'No biometric or passcode set..........................................');
        setState(() {
          isLoading = true;
          showCard = true;
        });
      } else {
        // If a screen lock is set, authenticate the user
        bool authenticated = await _biometricAuthUtil.authenticate();

        if (authenticated) {
          _fetchPasswords();
          setState(() {
            showCard = false;
            // Do not show the card, just authenticate
          });
        } else {
          setState(() {
            showCard = false;

            Navigator.of(context).pop();
          });
        }
      }
    } on PlatformException catch (e) {
      print("Error checking authentication: $e");
      setState(() {
        showCard = false; // If an error occurs, show the carm

        Navigator.of(context).pop();
      });
    }
  }

  void _fetchPasswords() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        isLoading = true;
      });

      try {
        String? encryptionKey =
            await SecureStorageUtil.getEncryptionKeyLocally();
        if (encryptionKey == null) {
          encryptionKey =
              await SecureStorageUtil.getEncryptionKeyFromFirestore();
        } else {
          print(
              'Encryption key stored locally............................................................: $encryptionKey');
        }

        if (encryptionKey == null) {
          throw Exception('Encryption key not found');
        }

        print(
            'Encryption key view............................................................: $encryptionKey');

        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('passwords')
            .get();

        List<Map<String, dynamic>> decryptedPasswords = [];

        for (var doc in snapshot.docs) {
          try {
            print(
                'encryted password view............................................................: ${doc['password']}');
            // Decrypt the password using the encryption key
            String decryptedPassword = await EncryptionUtil.decryptPassword(
                doc['password'], encryptionKey);

            print(
                'decripted password view............................................................: $decryptedPassword');
            decryptedPasswords.add({
              'id': doc.id,
              'platform': doc['platform'],
              'password': decryptedPassword,
            });
          } catch (e) {
            print('Error decrypting password for doc ${doc.id}: $e');
          }
        }

        setState(() {
          passwords = decryptedPasswords;
          filteredPasswords = decryptedPasswords;
          passwordVisibility = {
            for (var doc in decryptedPasswords) doc['id']: false,
          };
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching passwords: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterPasswords(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = passwords;
    } else {
      results = passwords
          .where((doc) =>
              doc['platform'].toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    }
    final int oldLength = filteredPasswords.length;
    final int newLength = results.length;

    setState(() {
      filteredPasswords = results;
    });

    if (newLength > oldLength) {
      for (int i = oldLength; i < newLength; i++) {
        _animatedListKey.currentState?.insertItem(i);
      }
    } else if (newLength < oldLength) {
      for (int i = oldLength - 1; i >= newLength; i--) {
        _animatedListKey.currentState?.removeItem(
          i,
          (context, animation) => SizedBox.shrink(),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _deletePassword(String docId, int index) async {
    await SoundUtil.playSound('sounds/notification.mp3');
    User? user = _auth.currentUser;
    if (user != null) {
      // Remove the item from the list with animation
      final removedItem = filteredPasswords.removeAt(index);
      passwords.remove(removedItem);
      final platfrom = removedItem['platform'];
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
                    passwordVisibility[removedItem['id']] ?? false
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
                          passwordVisibility[removedItem['id']] ?? false
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordVisibility[removedItem['id']] =
                                !(passwordVisibility[removedItem['id']] ??
                                    false);
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

      Provider.of<NotificationsProvider>(context, listen: false)
          .addNotification(
        'Password Delete',
        'Password deleted of $platfrom',
        'delete',
      );
    }
    setState(() {
      passwords = passwords;
      filteredPasswords = filteredPasswords;
    });
  }

  void _showDeleteConfirmationDialog(String docId, int index) async {
    await SoundUtil.playSound('sounds/warn.mp3');
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
  void dispose() {
    _animationController?.dispose();
    SoundUtil.dispose();
    super.dispose();
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
                    Expanded(
                      child: isLoading || !_isConnected
                          ? _buildSkeletonLoading()
                          : Column(
                              children: [
                                _buildAnimatedCard(
                                  child: CustomTextField(
                                    controller: searchController,
                                    labelText: 'Search by Website/App',
                                    prefixIcon: Icons.search,
                                    onChanged: _filterPasswords,
                                    autoFocus: false,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Expanded(
                                  child: filteredPasswords.isEmpty
                                      ? _buildAnimatedCard(
                                          child: Card(
                                          color: const Color.fromARGB(
                                              62, 6, 119, 211),
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white30,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ))
                                      : AnimatedList(
                                          key: _animatedListKey,
                                          initialItemCount:
                                              filteredPasswords.length,
                                          itemBuilder:
                                              (context, index, animation) {
                                            Map<String, dynamic> doc =
                                                filteredPasswords[index];
                                            bool isVisible =
                                                passwordVisibility[doc['id']] ??
                                                    false;
                                            return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(1,
                                                      0), // Slide from right to left
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeInOut,
                                                )),
                                                child: _buildAnimatedCard(
                                                  child: Card(
                                                    elevation: 10,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            const Color
                                                                .fromARGB(
                                                                255, 1, 11, 23),
                                                            const Color
                                                                .fromARGB(255,
                                                                16, 131, 224)
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      child: ListTile(
                                                        title: Text(
                                                          doc['platform'],
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          isVisible
                                                              ? doc['password']
                                                              : '•' *
                                                                  doc['password']
                                                                      .length,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                        trailing: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(
                                                                isVisible
                                                                    ? Icons
                                                                        .visibility
                                                                    : Icons
                                                                        .visibility_off,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  passwordVisibility[
                                                                          doc['id']] =
                                                                      !isVisible;
                                                                });
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.copy,
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                              onPressed: () =>
                                                                  _copyToClipboard(
                                                                      doc['password']),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.delete,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              onPressed: () =>
                                                                  _showDeleteConfirmationDialog(
                                                                      doc['id'],
                                                                      index),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ));
                                          },
                                        ),
                                ),
                              ],
                            ),
                    )
                  ],
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
                  FocusScope.of(context).unfocus();
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
            if (showCard)
              GestureDetector(
                onTap: () {
                  // Tapping outside closes the card
                  setState(() {
                    Vibration.vibrate(duration: 100);
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.6), // Dark overlay
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

            if (showCard)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomCard(),
              ),
          ],
        ));
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return FadeTransition(
      opacity: _animation!,
      child: child,
    );
  }

  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 70, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.black54, // Dark card background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration (Replace with actual image from assets)

          Image.asset(
            'assets/images/protect.png', // Add image in assets
            height: 120,
          ),
          SizedBox(height: 16),

          // Title
          Text(
            "Protect your Account",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),

          // Description
          Text(
            "Use screen lock to secure your Vaultix Account",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),

          // Enable Screen Lock Button
          ElevatedButton(
            onPressed: () async {
              final intent = AndroidIntent(
                action:
                    'android.settings.SECURITY_SETTINGS', // Opens security settings
                flags: <int>[
                  Flag.FLAG_ACTIVITY_NEW_TASK
                ], // Correct way to use the flag
              );
              await intent.launch();
              _authenticateAndFetchPasswords();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              backgroundColor: Color.fromARGB(255, 16, 99, 172),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "ENABLE SCREEN LOCK",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          // Do It Later Button
          TextButton(
            onPressed: () {
              setState(() {
                showCard = false;
                Navigator.of(context).pop();
              });
            },
            child: Text(
              "DO IT LATER",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSkeletonLoading() {
  return Shimmer.fromColors(
    baseColor: Colors.black.withValues(alpha: 0.5), // Dark base color
    highlightColor: Colors.black
        .withValues(alpha: 0.2), // S/ Slightly lighter highlight color
    child: Column(
      children: [
        // Skeleton for Search Bar
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: 10),
        // Skeleton for Password Cards
        Expanded(
          child: ListView.builder(
            itemCount: 5, // Number of skeleton items to show
            itemBuilder: (context, index) {
              return Card(
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
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[600],
                    ),
                    subtitle: Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.grey[600],
                      margin: EdgeInsets.only(top: 8),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 24,
                          height: 24,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 24,
                          height: 24,
                          color: Colors.grey[600],
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
  );
}
