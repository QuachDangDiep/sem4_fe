import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/login/Login.dart';

void main() {
  runApp(const MyApp());
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
