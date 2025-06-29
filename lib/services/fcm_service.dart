import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/Service/Constants.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initFCM() async {
    await _firebaseMessaging.requestPermission();

    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Xử lý nhận thông báo khi app mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Thông báo nhận được khi mở app: ${message.notification?.title}');
    });
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id'); // Bạn cần lưu user_id khi login

    if (userId != null) {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/fcm/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "fcmToken": token,
        }),
      );

      print("Gửi FCM token: ${response.statusCode}");
    }
  }
}
