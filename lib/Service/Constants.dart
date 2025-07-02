class Constants{


  static const String baseUrl = 'http://192.168.1.15:8080';


  static const String loginUrl = '$baseUrl/api/auth/login';
  static const String homeUrl = '$baseUrl/api/users';

  static const String sendotpUrl = '$baseUrl/api/password-reset/send-otp';
  static String verifyotpUrl(String email) => '$baseUrl/api/password-reset/verify-otp/$email';
  static String resetotpUrl(String email) => '$baseUrl/api/password-reset/reset-password/$email';

  static String searchQrCodeUrl(String code) => '$baseUrl/api/qrcodes/search?q=$code';
  static const String attendanceUrl = '$baseUrl/api/qrattendance/face';
  static const String workScheduleUrl = '$baseUrl/api/work-schedules';
  static const String qrScanUrl = '$baseUrl/api/qrattendance';

  // infomation
  static String employeeIdByUserIdUrl(String userId) =>
      '$baseUrl/api/employees/employee-id-by-user/$userId';

  static String employeeDetailUrl(String employeeId) =>
      '$baseUrl/api/employees/$employeeId';
  static const String leaveRegistrationUrl = '$baseUrl/api/leaves';

  static const String dancesUrl = '$baseUrl/api/attendances';

  static String summaryUrl(String formattedDate) => '$baseUrl/api/attendances/summary?date=$formattedDate';

}
