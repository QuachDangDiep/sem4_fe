class AuthService {
  static Future<bool> login(String email, String password) async {
    // Giả lập đăng nhập - thay bằng API thật nếu cần
    await Future.delayed(const Duration(seconds: 1)); // mô phỏng gọi API
    return email == 'admin@gmail.com' && password == '123456';
  }
}
