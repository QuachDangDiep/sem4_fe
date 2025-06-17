class Constants {
  static const String baseUrl = 'http://10.24.62.159:8080';

  static const String loginUrl = '$baseUrl/api/auth/login';
  static const String homeUrl = '$baseUrl/api/users';

  static const String sendotpUrl = '$baseUrl/api/password-reset/send-otp';
  static String verifyotpUrl(String email) => '$baseUrl/api/password-reset/verify-otp/$email';
  static String resetotpUrl(String email) => '$baseUrl/api/password-reset/reset-password/$email';

  static String searchQrCodeUrl(String code) => '$baseUrl/api/qrcodes/search?q=$code';

  static const String attendanceUrl = '$baseUrl/api/qrattendance/face';

  /// 🔽 API để lấy employeeId từ userId
  static String employeeIdByUserIdUrl(String userId) =>
      '$baseUrl/api/employees/employee-id-by-user/$userId';
}
