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
      theme: ThemeData(
        useMaterial3: false, // ✅ This is the correct place
      ),
      home: LoginScreen(
        onLogin: (username, password) {
          print('Login attempted with: $username, $password');
        },
      ),
    );
  }
}
