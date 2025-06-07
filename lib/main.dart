import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:sem4_fe/ui/login/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();       // ✅ Đảm bảo khởi tạo trước
  await FaceCamera.initialize();                   // ✅ Khởi tạo camera (bắt buộc)
  runApp(const MyApp());                           // ✅ Chạy app sau khi init
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(
        onLogin: (username, password) {
          print('Login attempted with: $username, $password');
          // Bạn có thể xử lý riêng gì thêm ở đây nếu muốn.
        },
      ),
    );
  }
}