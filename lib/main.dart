import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:sem4_fe/services/fcm_service.dart';
import 'package:sem4_fe/services/notification_service.dart';
import 'package:sem4_fe/ui/login/Login.dart';
import 'package:sem4_fe/ui/User/Notification/Notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ Global navigator key (dùng toàn ứng dụng)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FCMService.initFCM(); // Khởi tạo FCM

  String? savedToken = await getToken();
  String? userId = getUserIdFromToken(savedToken);

  if (userId != null) {
    await NotificationService.initialize(userId); // Khởi tạo thông báo nếu đã login
  }

  await FaceCamera.initialize();

  runApp(MyApp(savedToken: savedToken, userId: userId));
}

class MyApp extends StatelessWidget {
  final String? savedToken;
  final String? userId;

  const MyApp({super.key, this.savedToken, this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      home: savedToken != null && userId != null
          ? NotificationPage(userId: userId!) // ✅ chuyển vào trang noti nếu đã login
          : LoginScreen(
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
  return decoded['userId']; // Đảm bảo backend có trả userId trong token
}
