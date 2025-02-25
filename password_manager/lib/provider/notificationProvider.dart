import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsProvider with ChangeNotifier {
  List<Map<String, String>> _notifications = [];
  int _notificationCount = 0;

  List<Map<String, String>> get notifications => _notifications;
  int get notificationCount => _notificationCount;

  void addNotification(String title, String body, String type) async {
    _notifications.add({'title': title, 'body': body, 'type': type});
    _notificationCount++;
    await _saveNotifications();
    notifyListeners();
  }

  void removeNotification(int index) async {
    _notifications.removeAt(index);
    _notificationCount--;
    await _saveNotifications();
    notifyListeners();
  }

  void clearNotifications() async {
    _notifications.clear();
    _notificationCount = 0;
    await _saveNotifications();
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

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notifications': _notifications,
        'notificationCount': _notificationCount,
      }, SetOptions(merge: true));
    }
  }
}
