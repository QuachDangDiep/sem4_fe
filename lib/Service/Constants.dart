class Constants {
  static const String baseUrl = 'http://192.168.1.16:8080';

  static const String loginUrl = '$baseUrl/api/auth/login';
  static const String homeUrl = '$baseUrl/api/users';
  static const String rolesUrl = '$baseUrl/api/roles';

  static String leaveDetailUrl(String id) => '$baseUrl/api/leaves/$id';

  static const String employeeUrl = '$baseUrl/api/employees';

  static const String locationUrl = "$baseUrl/api/locations";

  static String changePasswordUrl(String userId) =>
      "$baseUrl/api/users/$userId/change-password";

  static const String workScheduleInfoUrl = "$baseUrl/api/work-schedule-infos";
  static const String departmentsUrl = "$baseUrl/api/departments";
  static const String positionsUrl = "$baseUrl/api/positions";

  static String myLeavesByEmployeeIdUrl(String employeeId) =>
      "$baseUrl/api/leaves/my-leaves/$employeeId";

  static const String sendotpUrl = '$baseUrl/api/password-reset/send-otp';

  static String verifyotpUrl(String email) =>
      '$baseUrl/api/password-reset/verify-otp/$email';

  static String resetotpUrl(String email) =>
      '$baseUrl/api/password-reset/reset-password/$email';

  static String searchQrCodeUrl(String code) =>
      '$baseUrl/api/qrcodes/search?q=$code';
  static const String attendanceUrl = '$baseUrl/api/qrattendance/face';
  static const String qrScanUrl = '$baseUrl/api/qrattendance';
  static const String activeQrAttendanceUrl = '$baseUrl/api/qrattendance/active';

  static String qrAttendanceDetailUrl(String qrId) =>
      '$baseUrl/api/qrattendance/$qrId';

  static String employeeHistoryByEmployeeIdUrl(String employeeId) =>
      '$baseUrl/api/employee-histories/employee/$employeeId';

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

  static const String getActiveDepartments = '$baseUrl/api/departments?status=Active';

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

  static String leavesByEmployeeUrl({
    required String employeeId,
    String? status,
  }) {
    String url = '$baseUrl/api/leaves/employee/$employeeId/leaves';
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }
    return url;
  }

  static String attendanceAppealsByEmployeeAndStatusUrl({
    required String employeeId,
    String? status,
  }) {
    String url = '$baseUrl/api/attendance-appeals/by-employee?employeeId=$employeeId';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    return url;
  }

  // ✅ API đăng ký OT (dùng createBulk)
  static const String registerOvertimeUrl = '$baseUrl/api/work-schedules/bulk';

// ✅ API duyệt OT
  static String approveOvertimeUrl(String scheduleId) =>
      '$baseUrl/api/work-schedules/approve-ot/$scheduleId';

// ✅ API xoá mềm
  static String softDeleteWorkScheduleUrl(String scheduleId) =>
      '$baseUrl/api/work-schedules/soft-delete/$scheduleId';

// ✅ API xem tất cả lịch (basic)
  static const String getAllWorkSchedulesUrl = '$baseUrl/api/work-schedules';

// ✅ API lấy lịch làm việc chi tiết theo khoảng thời gian
  static String workSchedulesByDateRangeUrl({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) =>
      '$baseUrl/api/work-schedules/range?employeeId=$employeeId&fromDate=$fromDate&toDate=$toDate';

// ✅ API xem lịch làm việc có thể chỉnh sửa
  static String editableWorkSchedulesUrl({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) =>
      '$baseUrl/api/work-schedules/editable?employeeId=$employeeId&fromDate=$fromDate&toDate=$toDate';


  static String updateEmployeeUrl(String employeeId) =>
      '$baseUrl/api/employees/$employeeId';


  static String overtimeWorkSchedulesByStatusUrl({
    required String employeeId,
    String? status, // cho phép null
    required String fromDate,
    required String toDate,
  }) {
    final base = '$baseUrl/api/work-schedules/employee/$employeeId/ot-by-status';
    final query = status != null && status.isNotEmpty
        ? '?status=$status&fromDate=$fromDate&toDate=$toDate'
        : '?fromDate=$fromDate&toDate=$toDate';
    return '$base$query';
  }
}
