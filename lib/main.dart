import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/ui/login/Login.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi chạy async code
  WidgetsFlutterBinding.ensureInitialized();

  // Đọc token trước khi khởi chạy app
  String? savedToken = await getToken();
  print('Token đã lưu khi khởi động app: $savedToken');

  WidgetsFlutterBinding.ensureInitialized();       // ✅ Bắt buộc trước khi init camera
  await FaceCamera.initialize();                   // ✅ Khởi tạo camera

  runApp(MyApp(savedToken: savedToken));
}

class MyApp extends StatelessWidget {
  final String? savedToken;

  const MyApp({super.key, this.savedToken});

  @override
  Widget build(BuildContext context) {
    // In ra token để kiểm tra (có thể bỏ sau khi debug)
    if (savedToken != null) {
      print('Token trong MyApp: $savedToken');
    }

    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: LoginScreen(
        onLogin: (username, password) {
          print('Login attempted with: $username, $password');
        },
      ),
    );
  }
}

Future<String?> getToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  } catch (e) {
    print('Lỗi khi đọc token: $e');
    return null;
  }
}