import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/login/Login.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Hàm xử lý đăng nhập (bạn sẽ đổi thành gọi API thực tế)
  Future<void> _handleLogin(String username, String password) async {
    // TODO: Gọi API, Firebase Auth, v.v.
    debugPrint('Username: $username, Password: $password');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

