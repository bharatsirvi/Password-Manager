import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsProvider with ChangeNotifier {
  List<Map<String, String>> _notifications = [];
  int _notificationCount = 0;

  List<Map<String, String>> get notifications => _notifications;
  int get notificationCount => _notificationCount;

  void addNotification(String title, String body, String type) {
    _notifications.add({'title': title, 'body': body, 'type': type});
    _notificationCount++;
    _saveNotifications();
    notifyListeners();
  }

  void removeNotification(int index) {
    _notifications.removeAt(index);
    _notificationCount--;
    _saveNotifications();
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _notificationCount = 0;
    _saveNotifications();
    notifyListeners();
  }

  void setNotifications(List<Map<String, String>> notifications, int count) {
    _notifications = notifications;
    _notificationCount = count;
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('notifications', jsonEncode(_notifications));
    prefs.setInt('notificationCount', _notificationCount);
  }
}
