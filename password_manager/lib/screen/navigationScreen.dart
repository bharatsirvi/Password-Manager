import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:password_manager/routes.dart';
import 'package:password_manager/screen/homeScreen.dart';
import 'package:password_manager/screen/notificationScreen.dart';
import 'package:password_manager/screen/profileScreen.dart';
import 'package:password_manager/provider/notificationProvider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:badges/badges.dart' as badges;
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  String _appBarTitle = 'Vaultix';
  final PageController _pageController = PageController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    return PopScope(
      // Disable default back button behavior
      onPopInvokedWithResult: (bool result, dynamic data) {
        if (_selectedIndex == 0) {
          // Close the app if on the Home screen

          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        } else {
          // Navigate back to the Home screen if on the Profile screen
          setState(() {
            _selectedIndex = 0;
            _appBarTitle = 'Vaultix';
            _onItemTapped(0);
          });
          // _pageController.jumpToPage(0);
        }
      },
      child: Scaffold(
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
                    NotificationIconWithBadge(),
                    IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: _showLogoutConfirmationDialog,
                    ),
                  ])
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
                  NotificationIconWithBadge(),
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
            return widget;
            // _FadeSlideTransition(
            //   child: widget,
            // );
          }).toList(),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 2, 36, 76), // Dark blue color
          ),
          child: CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            // color: const Color.fromARGB(123, 59, 84, 105),
            // buttonBackgroundColor: const Color.fromARGB(123, 59, 84, 105),
            color: const Color.fromARGB(121, 59, 94, 124),
            buttonBackgroundColor: const Color.fromARGB(121, 59, 94, 105),
            height: 60,
            items: [
              CurvedNavigationBarItem(
                child: Icon(Icons.home),
                label: 'Home',
              ),
              CurvedNavigationBarItem(
                child: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            index: _selectedIndex,
            onTap: _onItemTapped,
          ),
          // BottomNavigationBar(

          //   items: const <BottomNavigationBarItem>[
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.home),
          //       label: 'Home',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.person),
          //       label: 'Account',
          //     ),
          //   ],
          //   currentIndex: _selectedIndex,
          //   onTap: _onItemTapped,
          // ),
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

class NotificationIconWithBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notificationCount =
        Provider.of<NotificationsProvider>(context).notificationCount;

    return InkWell(
      borderRadius: BorderRadius.all(Radius.circular(50)),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NotificationScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: badges.Badge(
        gradient: LinearGradient(
          tileMode: TileMode.clamp,
          colors: [
            const Color.fromARGB(125, 244, 67, 54),
            const Color.fromARGB(137, 255, 86, 34)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: badges.BadgeShape.circle, // Badge shape

        position:
            badges.BadgePosition.topEnd(top: -2, end: 6), // Adjust position
        badgeContent: Text(
          '$notificationCount',
          key: ValueKey<int>(notificationCount),
          style: TextStyle(
            color: Colors.white,
            fontSize: notificationCount > 9 ? 10 : 12, // Adjust font size
            fontWeight: FontWeight.bold,
          ),
        ),

        // Badge background color
        padding: EdgeInsets.all(6), // Adjust padding
        borderRadius: BorderRadius.circular(10), // Rounded corners
        elevation: 2, // Shadow
        animationType: badges.BadgeAnimationType.scale, // Animation type
        toAnimate: true,
        animationDuration: Duration(milliseconds: 300),
        showBadge: notificationCount >
            0, // Show badge only when there are notifications
        child: IconButton(
          icon: Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    NotificationScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedNotificationBadge extends StatelessWidget {
  final int count;

  const AnimatedNotificationBadge({required this.count});
  // Adjust size for double-digit numbers

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Container(
        key: ValueKey<int>(count),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.red,
          gradient: LinearGradient(
            colors: [Colors.red, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
