import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/login/Login.dart'; // Thêm import màn hình Login nếu cần

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isLoading = false;
  String _error = '';
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ mật khẩu và xác nhận.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _error = 'Mật khẩu và xác nhận không khớp.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final url = Uri.parse(Constants.resetotpUrl(widget.email));
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final json = jsonDecode(res.body);

      if (res.statusCode == 200 && json['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đổi mật khẩu thành công'),
              backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() => _error = json['message'] ?? 'Đổi mật khẩu thất bại');
      }
    } catch (e) {
      setState(() => _error = 'Lỗi kết nối: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);
    const gray = Colors.grey;

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.08;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFB300),
            Color(0xFFFF8F00),
            Color(0xFFF57C00),
            Color(0xFFEF6C00)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                        width: 420, height: 420, color: Colors.white),
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
                          Colors.white, BlendMode.srcIn),
                      child: Image.network(
                        'https://app.easyhrm.vn/image/easyhrmlogo.png',
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 35),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.only(bottom: 70),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                              Border.all(color: orange, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          color: orange),
                                      onPressed: () =>
                                          Navigator.pop(context),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Đặt lại mật khẩu',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nhập mật khẩu mới cho tài khoản:',
                                  style: TextStyle(color: orange),
                                ),
                                const SizedBox(height: 6),
                                Text(widget.email,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent)),
                                const SizedBox(height: 24),
                                const Text('Mật khẩu mới (*)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: !_showPassword,
                                  cursorColor: orange,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập mật khẩu',
                                    prefixIcon: Icon(Icons.lock,
                                        color: (_passwordFocusNode
                                            .hasFocus ||
                                            _showPassword)
                                            ? orange
                                            : gray),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: _showPassword
                                            ? orange
                                            : gray,
                                      ),
                                      onPressed: () => setState(() {
                                        _showPassword = !_showPassword;
                                      }),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide:
                                      const BorderSide(color: gray),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: orange, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Xác nhận mật khẩu (*)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _confirmController,
                                  focusNode: _confirmFocusNode,
                                  obscureText: !_showConfirm,
                                  cursorColor: orange,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập lại mật khẩu',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: (_confirmFocusNode
                                            .hasFocus ||
                                            _showConfirm)
                                            ? orange
                                            : gray),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showConfirm
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: _showConfirm
                                            ? orange
                                            : gray,
                                      ),
                                      onPressed: () => setState(() {
                                        _showConfirm = !_showConfirm;
                                      }),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide:
                                      const BorderSide(color: gray),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: orange, width: 2),
                                    ),
                                  ),
                                ),
                                if (_error.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(_error,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 14)),
                                ],
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: orange,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                        color: Colors.white)
                                        : const Text(
                                      'Xác nhận',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
