import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String get otpCode => _controllers.map((e) => e.text).join();

  @override
  void initState() {
    super.initState();
    for (var node in _focusNodes) {
      node.addListener(() => setState(() {})); // Cập nhật khi focus thay đổi
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = otpCode;
    if (otp.length < 6 || otp.contains(RegExp(r'\D'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ 6 chữ số OTP')),
      );
      return;
    }

    final url = Uri.parse(Constants.verifyotpUrl(widget.email));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'otpCode': otp}),
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      final res = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${res['message']}')),
      );
    }
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 50,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _focusNodes[index].hasFocus
                  ? Colors.orange
                  : Colors.grey.shade300,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            final chars = value.replaceAll(RegExp(r'\D'), '').split('');
            for (int i = 0; i < chars.length; i++) {
              if (index + i < _controllers.length) {
                _controllers[index + i].text = chars[i];
              }
            }
            final nextIndex = index + chars.length;
            if (nextIndex < _focusNodes.length) {
              FocusScope.of(context).requestFocus(_focusNodes[nextIndex]);
            } else {
              _focusNodes.last.unfocus();
            }
          } else {
            if (value.isNotEmpty && index < _focusNodes.length - 1) {
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          }
        },
      ),
    );
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
                    clipper: _OtpBottomClipper(),
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
                        const Icon(Icons.broken_image,
                            size: 70, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 35),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.88,
                            constraints: const BoxConstraints(
                              maxWidth: 460,
                              minHeight: 400,
                            ),
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.only(bottom: 70),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFF9800), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  spreadRadius: 4,
                                  blurRadius: 12,
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
                                          color: Colors.orange),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Xác thực mã OTP',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Nhập mã OTP gồm 6 chữ số được gửi tới email:',
                                  style: TextStyle(color: Colors.orange),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.email,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2424E6)),
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  children:
                                  List.generate(6, _buildOtpField),
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFFFF9800),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Xác minh',
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
                        // Positioned(
                        //   bottom: -20,
                        //   left: 0,
                        //   right: 0,
                        //   child: Image.asset(
                        //     'assets/hr.png',
                        //     height: 200,
                        //     fit: BoxFit.contain,
                        //   ),
                        // ),
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

class _OtpBottomClipper extends CustomClipper<Path> {
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
