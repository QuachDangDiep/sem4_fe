import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChangePasswordPage extends StatefulWidget {
  final String token;
  final String userId;

  const ChangePasswordPage({Key? key,required this.token, required this.userId}) : super(key: key);

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("Token không tồn tại");

      final response = await http.put(
        Uri.parse('https://your-api-url.com/api/users/${widget.userId}/change-password'),
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
      if (response.statusCode == 200) {
        if (responseData["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Đổi mật khẩu thành công")),
          );
          Navigator.pop(context);
        } else {
          throw Exception(responseData["message"]);
        }
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

  InputDecoration _inputDecoration(String label, bool obscure, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[100],
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
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
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: _inputDecoration("Mật khẩu hiện tại", _obscureCurrent, () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                }),
                validator: (value) =>
                (value == null || value.isEmpty) ? "Vui lòng nhập mật khẩu hiện tại" : null,
              ),
              const SizedBox(height: 20),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: _inputDecoration("Mật khẩu mới", _obscureNew, () {
                  setState(() => _obscureNew = !_obscureNew);
                }),
                validator: (value) =>
                (value == null || value.length < 6) ? "Mật khẩu mới phải tối thiểu 6 ký tự" : null,
              ),
              const SizedBox(height: 20),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration("Xác nhận mật khẩu", _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                }),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Vui lòng xác nhận mật khẩu";
                  if (value != _newPasswordController.text) return "Mật khẩu không khớp";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitChangePassword,
                icon: const Icon(Icons.lock_reset, color: Colors.white),
                label: const Text("Đổi mật khẩu", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
