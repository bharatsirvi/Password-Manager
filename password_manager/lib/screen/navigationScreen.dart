import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/profileScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:password_manager/utills/sound.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  String _appBarTitle = 'Vaultix';
  final PageController _pageController = PageController();

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = index == 0 ? 'Vaultix' : 'Profile';
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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

  @override
  void dispose() {
    _pageController.dispose();
    SoundUtil.dispose();
    super.dispose();
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
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _showLogoutConfirmationDialog,
                ),
              ],
            )
          : AppBar(
              automaticallyImplyLeading: false,
              backgroundColor:
                  const Color.fromARGB(255, 2, 36, 76), // Dark blue color
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => RadialGradient(
                      colors: [
                        const Color.fromARGB(255, 98, 214, 102),
                        const Color.fromARGB(255, 69, 128, 71),
                      ],
                      center: Alignment.center,
                      radius: 0.5,
                    ).createShader(bounds),
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 5),
                  Image.asset(
                    'assets/images/profilename.png', // Replace with your logo asset path
                    height: 25,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _showLogoutConfirmationDialog,
                ),
              ],
            ), // Hide AppBar when _selectedIndex is not 0
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
            _appBarTitle = index == 0 ? 'Vaultix' : 'Profile';
          });
        },
        children: _widgetOptions.map((widget) {
          return _FadeSlideTransition(
            child: widget,
          );
        }).toList(),
      ),
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

class _FadeSlideTransition extends StatelessWidget {
  final Widget child;

  const _FadeSlideTransition({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModalRoute.of(context)!.animation!,
      builder: (context, child) {
        const begin = Offset(1.0, 0.0); // Slide from right to left
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var slideTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var slideAnimation =
            ModalRoute.of(context)!.animation!.drive(slideTween);

        var fadeTween = Tween(begin: 0.0, end: 1.0);
        var fadeAnimation = ModalRoute.of(context)!.animation!.drive(fadeTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
