import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:sem4_fe/services/fcm_service.dart';
import 'package:sem4_fe/services/notification_service.dart';
import 'package:sem4_fe/ui/login/Login.dart';
import 'package:sem4_fe/ui/User/Notification/Notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ Handler cho thông báo khi app bị kill (background)
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔕 Background message received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // ✅ Init FCM
  await FCMService.initFCM();

  // ✅ Lấy token từ local (nếu có để dùng cho FCM, không để tự động đăng nhập)
  String? savedToken = await getToken();
  String? userId = getUserIdFromToken(savedToken);

  if (userId != null) {
    await NotificationService.initialize(userId); // Load FCM nếu có token
  }

  // ✅ Init FaceCamera
  await FaceCamera.initialize();

  runApp(const MyApp()); // ✅ KHÔNG truyền token để tự động đăng nhập nữa
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      home: LoginScreen(
        onLogin: (username, password) {
          print('Login attempted with: $username, $password');
        },
      ),
    );
  }
}

// ✅ Lấy token từ SharedPreferences
Future<String?> getToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  } catch (e) {
    print('❌ Lỗi khi đọc token: $e');
    return null;
  }
}

// ✅ Giải mã token và lấy userId
String? getUserIdFromToken(String? token) {
  if (token == null || JwtDecoder.isExpired(token)) return null;
  final decoded = JwtDecoder.decode(token);
  print('🔍 Thông tin từ JWT: $decoded');
  return decoded['userId']; // Đảm bảo BE có trả userId trong token
}
