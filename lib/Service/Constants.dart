class Constants{
  static const String serverIp = '10.24.8.75'; // Thay đổi theo IP thật của bạn
  static const int serverPort = 8080; // hoặc cổng khác nếu backend chạy cổng khác

  static const String serverUrl = 'http://$serverIp:$serverPort';

  static const String baseUrl = 'http://10.0.2.2:8080';

  static const String loginUrl = '$baseUrl/api/auth/login';

  static const String homeUrl = '$baseUrl/api/users';

  static const String sendotpUrl = '$baseUrl/api/password-reset/send-otp';
  static String verifyotpUrl(String email) => '$baseUrl/api/password-reset/verify-otp/$email';
  static String resetotpUrl(String email) => '$baseUrl/api/password-reset/reset-password/$email';
}