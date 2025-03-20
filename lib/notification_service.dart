import 'package:myfinance/main.dart';

import 'finance_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String> getToken() async {
    return await _messaging.getToken() ?? '';
  }

  void logOut(){
    _messaging.deleteToken();
  }

  Future<void> requestNotificationPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> initialize(BuildContext context) async {
    await requestNotificationPermission();
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotificationDialog(navigatorKey.currentContext!, message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _showNotificationDialog(navigatorKey.currentContext!, message);
    });
  }

  void _showNotificationDialog(BuildContext context, RemoteMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message.notification?.title ?? 'New Notification'),
          content: Text(message.notification?.body ?? ''),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Optional: Method to handle notification data
  void handleNotificationData(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      // Handle any custom data sent with the notification
      debugPrint('Notification data: ${message.data}');
    }
  }
} 