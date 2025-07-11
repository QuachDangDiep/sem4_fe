import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:face_camera/face_camera.dart';
import 'package:sem4_fe/services/fcm_service.dart';
import 'package:sem4_fe/services/notification_service.dart';
import 'package:sem4_fe/ui/login/Login.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// ✅ Handler khi app ở trạng thái background hoặc terminated
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔕 [Background] message received: ${message.notification?.title}");
}

/// ✅ Hiển thị local notification
void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Thông báo hệ thống',
          channelDescription: 'Thông báo từ hệ thống',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

/// ✅ Cấu hình Local Notifications
Future<void> setupFlutterLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Đăng ký handler cho background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // ✅ Cấu hình local notifications
  await setupFlutterLocalNotifications();

  // ✅ Xin quyền hiển thị notification (Android 13+)
  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission();
  print('🔐 Notification permission: ${settings.authorizationStatus}');

  // ✅ Xử lý khi nhận được thông báo khi app đang chạy (foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📥 [Foreground] Notification: ${message.notification?.title}");
    showFlutterNotification(message);
  });

  // ✅ Khởi tạo FCM
  await FCMService.initFCM();

  // ✅ Lấy token đăng nhập từ local
  String? savedToken = await getToken();
  String? userId = getUserIdFromToken(savedToken);

  if (userId != null) {
    await NotificationService.initialize(userId);
  }

  // ✅ Khởi tạo FaceCamera
  await FaceCamera.initialize();
  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());
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
  return decoded['userId'];
}
