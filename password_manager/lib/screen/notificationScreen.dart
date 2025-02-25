import 'package:flutter/material.dart';
import 'package:password_manager/utills/sound.dart';
import 'package:provider/provider.dart';
import 'package:password_manager/provider/notificationProvider.dart';

class NotificationScreen extends StatelessWidget {
  void _clearNotifications(BuildContext context) async {
    await SoundUtil.playSound('sounds/delete.mp3');
    Provider.of<NotificationsProvider>(context, listen: false)
        .clearNotifications();
    Navigator.of(context).pop();
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
            return notificationsProvider.notifications.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: notificationsProvider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification =
                          notificationsProvider.notifications[index];
                      final type = notification['type'];
                      final color = _getNotificationColor(type);

                      return Dismissible(
                        key: Key(notification['title']!),
                        onDismissed: (direction) {
                          notificationsProvider.removeNotification(index);
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
                                notificationsProvider.removeNotification(index);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
          },
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
    await SoundUtil.playSound('sounds/alert.mp3');
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
