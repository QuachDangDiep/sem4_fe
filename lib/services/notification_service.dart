import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sem4_fe/services/api_service.dart';

class NotificationService {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(String userId) async {
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();
    print("📲 FCM Token: $token");

    if (token != null) {
      await ApiService.sendFCMTokenToBackend(userId, token);
    }

    // Hiển thị thông báo foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          message.notification!.title ?? 'Thông báo',
          message.notification!.body ?? '',
        );
      }
    });

    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("🔔 Clicked notification (background)");
    });

    // Android local config
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(settings);
  }

  static void showLocalNotification(String title, String body) {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Thông báo',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(0, title, body, details);
  }
}
