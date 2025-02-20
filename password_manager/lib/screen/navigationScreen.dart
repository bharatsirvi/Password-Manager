import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/profileScreen.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  String _appBarTitle = 'Vaultix';

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = index == 0 ? 'Vaultix' : 'Profile';
    });
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

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor:
                  const Color.fromARGB(255, 2, 36, 76), // Dark blue color
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/sym2.png', // Replace with your logo asset path
                    height: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    _appBarTitle,
                    style: TextStyle(
                      fontFamily: 'Tenada',
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _showLogoutConfirmationDialog,
                ),
              ],
            )
          : null, // Hide AppBar when _selectedIndex is not 0
      body: _widgetOptions.elementAt(_selectedIndex),
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
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
