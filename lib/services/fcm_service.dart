import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/services/api_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initFCM() async {
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();
    print("📱 FCM Token: $token");

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        await ApiService.sendFCMTokenToBackend(userId, token);
      }
    }

    // Khi app đang mở
    FirebaseMessaging.onMessage.listen((message) {
      print("Start login"); // ← Đặt breakpoint tại dòng này

      print("🔔 Nhận FCM foreground: ${message.notification?.title}");
    });
  }

  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }
}
