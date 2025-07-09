class Constants {
  static const String baseUrl = 'http://10.0.2.2:8080';

  static const String loginUrl = '$baseUrl/api/auth/login';
  static const String homeUrl = '$baseUrl/api/users';

  static String myLeavesByEmployeeIdUrl(String employeeId) =>
      "$baseUrl/api/leaves/my-leaves/$employeeId";

  static const String sendotpUrl = '$baseUrl/api/password-reset/send-otp';
  static String verifyotpUrl(String email) => '$baseUrl/api/password-reset/verify-otp/$email';
  static String resetotpUrl(String email) => '$baseUrl/api/password-reset/reset-password/$email';

  static String searchQrCodeUrl(String code) => '$baseUrl/api/qrcodes/search?q=$code';
  static const String attendanceUrl = '$baseUrl/api/qrattendance/face';
  static const String qrScanUrl = '$baseUrl/api/qrattendance';
  static const String activeQrAttendanceUrl = '$baseUrl/api/qrattendance/active';

  // static String qrAttendancesByEmployeeUrl(String employeeId) =>
  //     '$baseUrl/api/qrattendance/with-employees/$employeeId';

  static const String workScheduleUrl = '$baseUrl/api/work-schedules/filter';
  static String workScheduleFilterRangeUrl({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) =>
      '$baseUrl/api/work-schedules/filter-range?employeeId=$employeeId&fromDate=$fromDate&toDate=$toDate';

  static String employeeIdByUserIdUrl(String userId) =>
      '$baseUrl/api/employees/employee-id-by-user/$userId';
  static String employeeDetailUrl(String employeeId) =>
      '$baseUrl/api/employees/$employeeId';
  static String get employeeHistoriesUrl => '$baseUrl/api/employee-histories';
  static const String leaveRegistrationUrl = '$baseUrl/api/leaves';

  static const String dancesUrl = '$baseUrl/api/attendances';

  static String getRoleByIdUrl(String roleId) => '$baseUrl/api/roles/$roleId';

  static String summaryUrl(String formattedDate) =>
      '$baseUrl/api/attendances/summary?date=$formattedDate';

  static const String workScheduleInfosUrl = '$baseUrl/api/work-schedule-infos';
  static const String registerWorkScheduleUrl = '$baseUrl/api/work-schedules';
  static String updateWorkScheduleUrl(String scheduleId) =>
      '$baseUrl/api/work-schedules/$scheduleId';

  static const String attendanceAppealsUrl = '$baseUrl/api/attendance-appeals';

  static String attendanceAppealsByEmployeeUrl(String employeeId) =>
      '$baseUrl/api/attendance-appeals?employeeId=$employeeId';

  static String postAttendanceAppealUrl = '$baseUrl/api/attendance-appeals';


  static String qrAttendancesByEmployeeUrl(String employeeId) =>
      '$baseUrl/api/qrattendance/by-employee?employeeId=$employeeId';

  static String attendancesByEmployeeUrl(String employeeId) =>
      '$baseUrl/api/attendances/by-employee?employeeId=$employeeId';

  static String filterAttendancesUrlWithStatus({
    required String employeeId,
    required String fromDate,
    required String toDate,
    String? status,
  }) {
    String url =
        '$baseUrl/api/attendances/filter-range?employeeId=$employeeId&fromDate=$fromDate&toDate=$toDate';

    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }

    return url;
  }


}
