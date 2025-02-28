import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:password_manager/utills/internetConnect.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:provider/provider.dart';
import 'package:password_manager/provider/notificationProvider.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  void _clearNotifications(BuildContext context) async {
    Provider.of<NotificationsProvider>(context, listen: false)
        .clearNotifications();
    await SoundUtil.playSound('sounds/notification.mp3');
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenForConnectivityChanges();
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

  @override
  void dispose() {
    SoundUtil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color.fromARGB(255, 2, 36, 76), // Dark blue color
        title: Row(
          children: [
            Image.asset(
              'assets/images/notification_name.png', // Replace with your logo asset path
              height: 20,
            ),
            SizedBox(width: 10),
            Icon(
              Icons.notifications,
              color: Colors.white,
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              _showClearAllConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: Stack(children: [
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
        Consumer<NotificationsProvider>(
          builder: (context, notificationsProvider, child) {
            final notifications =
                notificationsProvider.notifications.reversed.toList();
            return notifications.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final type = notification['type'];
                      final color = _getNotificationColor(type);
                      return Dismissible(
                        key: Key(notification['title']! + index.toString()),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            return true;
                          }
                          return false;
                        },
                        onUpdate: (details) {
                          if (details.direction ==
                              DismissDirection.endToStart) {
                            notificationsProvider.removeNotification(
                                notificationsProvider.notifications.length -
                                    1 -
                                    index);
                          }
                        },
                        onDismissed: (direction) {
                          notificationsProvider.removeNotification(
                              notificationsProvider.notifications.length -
                                  1 -
                                  index);
                        },
                        background: Container(
                          color: Colors.transparent,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                        ),
                        child: Card(
                          color: color.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 15.0,
                            ),
                            title: Text(
                              notification['title']!,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              notification['body']!,
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close, color: Colors.white70),
                              onPressed: () {
                                notificationsProvider.removeNotification(
                                    notificationsProvider.notifications.length -
                                        1 -
                                        index);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
          },
        ),
        if (!_isConnected)
          Positioned(
            top: 0,
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
      ]),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'neutral':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'warning':
      case 'delete':
        return Colors.red;
      case 'info':
        return Colors.blue;
      case 'update':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  void _showClearAllConfirmationDialog(BuildContext context) async {
    await SoundUtil.playSound('sounds/warn.mp3');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Notifications'),
          content: Text('Are you sure you want to clear all notifications?'),
          actions: [
            TextButton(
              child: Text('Cancel',
                  style: TextStyle(
                    color: Colors.green,
                  )),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Clear All',
                  style: TextStyle(
                    color: Colors.white,
                  )),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
              ),
              onPressed: () {
                _clearNotifications(context);
              },
            ),
          ],
        );
      },
    );
  }
}
