import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';

class ChangePasswordPage extends StatefulWidget {
  final String token;

  const ChangePasswordPage({Key? key, required this.token}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = widget.token;

      if (token.isEmpty) throw Exception("Token không tồn tại");

      // ✅ Giải mã token để lấy userId
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['userId'];

      if (userId == null || userId.toString().isEmpty) {
        throw Exception("Không tìm thấy userId trong token");
      }

      final response = await http.put(
        Uri.parse(Constants.changePasswordUrl(userId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "currentPassword": _currentPasswordController.text,
          "newPassword": _newPasswordController.text,
          "confirmPassword": _confirmPasswordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đổi mật khẩu thành công")),
        );
        Navigator.pop(context);
      } else {
        throw Exception(responseData["message"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool obscure, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
        color: Colors.grey,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Mật khẩu hiện tại
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: _inputDecoration("Mật khẩu hiện tại", Icons.lock_outline, _obscureCurrent, () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                }),
                validator: (value) =>
                value == null || value.isEmpty ? "Vui lòng nhập mật khẩu hiện tại" : null,
              ),
              const SizedBox(height: 20),

              // Mật khẩu mới
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: _inputDecoration("Mật khẩu mới", Icons.vpn_key, _obscureNew, () {
                  setState(() => _obscureNew = !_obscureNew);
                }),
                validator: (value) =>
                value == null || value.length < 6 ? "Mật khẩu mới phải tối thiểu 6 ký tự" : null,
              ),
              const SizedBox(height: 20),

              // Xác nhận mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration("Xác nhận mật khẩu", Icons.verified_user, _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                }),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Vui lòng xác nhận mật khẩu";
                  if (value != _newPasswordController.text) return "Mật khẩu không khớp";
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút gửi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitChangePassword,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Đổi mật khẩu", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
