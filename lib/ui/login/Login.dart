import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/ui/User/Homeuser/Homeuser.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/login/screens/send_otp_screen.dart';
import 'package:sem4_fe/ui/hr//home/HomeHr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final Function(String username, String password)? onLogin;

  const LoginScreen({Key? key, this.onLogin}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('[DEBUG] Đang kết nối đến: ${Constants.loginUrl}'); // Thêm dòng debug này
      final response = await http.post(
        Uri.parse(Constants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] Phản hồi từ server: ${response.statusCode}'); // Thêm dòng debug này
      final data = jsonDecode(response.body);
      print('API Full Response: $data');

      if (response.statusCode == 200) {
        final token = data['result']['token']?.toString() ?? '';
        if (token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không nhận được token')),
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print('Đã lưu token: $token');

        String role = '';
        try {
          final decodedToken = JwtDecoder.decode(token);
          role = (decodedToken['role']?.toString() ?? '').toLowerCase();
          print('Decoded role from token: $role');
        } catch (e) {
          print('Không thể decode token: $e');
          role = data['result']['role']?.toString().trim().toLowerCase() ?? '';
        }

        print('Final determined role: $role');

        if (role == 'hr') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeHRPage(username: username, token: token),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(username: username, token: token),
            ),
          );
        }
      } else {
        final message = data['message'] ?? 'Đăng nhập thất bại (Mã lỗi: ${response.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on TimeoutException {
      print('[DEBUG] Lỗi timeout khi kết nối đến server'); // Thêm debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server không phản hồi. Vui lòng thử lại sau')),
      );
    } on SocketException catch (e) {
      print('[DEBUG] Lỗi kết nối Socket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( // Bỏ const ở đây
          content: Text('Không thể kết nối đến server. Đảm bảo:'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'XEM',
            onPressed: () {
              // Thêm hành động khi nhấn nút XEM
              print('Người dùng nhấn XEM để xem chi tiết lỗi');
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('[DEBUG] Lỗi không xác định: $e\n$stackTrace'); // Thêm debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().split('\n').first}'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.08;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB300),
            Color(0xFFFF8F00),
            Color(0xFFF57C00),
            Color(0xFFEF6C00),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Transform.translate(
                offset: const Offset(-130, 80),
                child: Transform.rotate(
                  angle: -0.2,
                  child: ClipPath(
                    clipper: BottomLeftCutClipper(),
                    child: Container(
                      width: 420,
                      height: 420,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: Image.network(
                        'https://app.easyhrm.vn/image/easyhrmlogo.png',
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 48),
                      ),
                    ),
                    const SizedBox(height: 35),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 400),
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.only(bottom: 70),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF9800), // màu viền cam
                                width: 2, // độ dày viền
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  spreadRadius: 4,
                                  blurRadius: 12,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 350),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Enter your username',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                          ),
                                          const Text('Remember me'),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const SendOtpScreen(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFFFF9800),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF9800),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                          color: Colors.white)
                                          : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: 0,
                          right: 0,
                          child: Image.asset(
                            'assets/hr.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomLeftCutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height * 0.6);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}