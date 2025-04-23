import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});
  final Future<void> Function(String username, String password) onLogin;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onLogin(
        _usernameCtrl.text.trim(),
        _pwCtrl.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account != null) {
        // Nếu đăng nhập thành công
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        // Nếu đăng nhập thành công
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook sign-in failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook sign-in error: $e')),
      );
    }
  }

  // Define _socialButton method
  Widget _socialButton(String imagePath, String label, VoidCallback onPressed) {
    return SizedBox(
      width: 180,
      height: 60,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE6CAE4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/anh.png', height: 120),
                const SizedBox(height: 20),
                const Text(
                  'Ứng dụng chấm công',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _usernameCtrl,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your username' : null,
                  decoration: InputDecoration(
                    labelText: 'User Name',
                    labelStyle: TextStyle(color: Color(0xFF8D8484), fontSize: 15),  // Màu chữ label
                    hintStyle: TextStyle(color: Color(0xFF8D8484), fontSize: 15),   // Màu chữ hint
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),  // Bo góc 20
                      borderSide: BorderSide(color: Color(0xFF8D8484)),  // Màu border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Color(0xFF8D8484)),  // Màu border khi focus
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pwCtrl,
                  obscureText: _obscure,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Color(0xFF8D8484), fontSize: 15),  // Màu chữ label
                    hintStyle: TextStyle(color: Color(0xFF8D8484), fontSize: 15),   // Màu chữ hint
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),  // Bo góc 20
                      borderSide: BorderSide(color: Color(0xFF8D8484)),  // Màu border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Color(0xFF8D8484)),  // Màu border khi focus
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFF8D8484),  // Màu icon
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Row(
                //   children: [
                //     const Text("You do not have an account, please "),
                //     GestureDetector(
                //       onTap: () {
                //         // Chuyển tới màn đăng ký
                //       },
                //       child: const Text(
                //         "register",
                //         style: TextStyle(color: Colors.blue),
                //       ),
                //     )
                //   ],
                // ),
                // const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2424E6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Xác Nhận',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _socialButton(
                        'assets/google.png', 'Google', _signInWithGoogle),
                    _socialButton(
                        'assets/facebook.png', 'Facebook', _signInWithFacebook),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Trợ giúp",
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
