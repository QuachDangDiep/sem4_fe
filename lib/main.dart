import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/login/Login.dart';

void main() {
  runApp(MaterialApp(
      home: LoginScreen(
        onLogin: (String username, String password) async {
        print('Username: $username, Password: $password');
      },
      )
  ));
}

class ContentApp extends StatelessWidget {
  const ContentApp({super.key});

  @override
  Widget build(BuildContext context){
    return const Placeholder();
  }
}