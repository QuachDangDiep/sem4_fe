import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class Attendance {
  final String attendanceId;
  final String employeeId;
  final DateTime attendanceDate;
  final double totalHours;
  final String status;

  Attendance({
    required this.attendanceId,
    required this.employeeId,
    required this.attendanceDate,
    required this.totalHours,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendanceId'],
      employeeId: json['employeeId'] ?? json['employee']['employeeId'],
      attendanceDate: DateTime.parse(json['attendanceDate']),
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0.0,
      status: json['status'],
    );
  }
}

class AttendanceService {
  final String token;

  AttendanceService({required this.token});

  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Attendance>> getAttendancesByEmployeeAndDateRange({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) async {
    final url = Constants.filterAttendancesUrlWithStatus(
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
      status: null,
    );

    final res = await http.get(Uri.parse(url), headers: _buildHeaders());

    if (res.statusCode == 200) {
      return (json.decode(res.body) as List)
          .map((e) => Attendance.fromJson(e))
          .toList();
    }
    throw Exception('Không thể tải danh sách chấm công theo điều kiện');
  }

  Future<int> getTotalWorkingDays({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) async {
    final url = Constants.filterAttendancesUrlWithStatus(
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
    );

    final res = await http.get(Uri.parse(url), headers: _buildHeaders());

    if (res.statusCode == 200) {
      final List list = json.decode(res.body);

      // Nhóm theo ngày chấm công
      final Map<String, List<dynamic>> groupedByDate = {};

      for (var item in list) {
        final date = item['attendanceDate'];
        if (date == null) continue;
        groupedByDate.putIfAbsent(date, () => []).add(item);
      }

      int count = 0;

      for (var entry in groupedByDate.entries) {
        final records = entry.value;

        // Nếu trong ngày có ÍT NHẤT 1 bản ghi KHÔNG phải Absent thì tính là 1 ngày công
        final hasValidStatus = records.any((r) {
          final status = r['status']?.toString().toLowerCase();
          return status != 'absent';
        });

        if (hasValidStatus) count++;
      }

      return count;
    }

    throw Exception('Không thể lấy số ngày chấm công');
  }

  Future<int> getTotalOvertimeDays({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) async {
    final url = Constants.overtimeWorkSchedulesByStatusUrl(
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
      status: 'Active',
    );

    final res = await http.get(Uri.parse(url), headers: _buildHeaders());
    if (res.statusCode == 200) {
      final List list = json.decode(res.body);
      return list.length;
    }
    throw Exception('Không thể lấy số ngày OT');
  }

  Future<int> getTotalLeaveDays({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) async {
    final url = Constants.leavesByEmployeeUrl(
      employeeId: employeeId,
      status: 'Approved',
    );

    final res = await http.get(Uri.parse(url), headers: _buildHeaders());
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      final from = DateTime.parse(fromDate);
      final to = DateTime.parse(toDate);

      final filtered = data.where((e) {
        final fromStr = e['leaveStartDate']?.toString();
        final toStr = e['leaveEndDate']?.toString();

        if (fromStr == null || toStr == null) return false;

        final leaveFrom = DateTime.tryParse(fromStr);
        final leaveTo = DateTime.tryParse(toStr);

        if (leaveFrom == null || leaveTo == null) return false;

        return leaveFrom.isBefore(to.add(const Duration(days: 1))) &&
            leaveTo.isAfter(from.subtract(const Duration(days: 1)));
      }).toList();

      int totalLeaveDays = 0;
      for (var leave in filtered) {
        final start = DateTime.parse(leave['leaveStartDate']);
        final end = DateTime.parse(leave['leaveEndDate']);
        final rangeStart = start.isBefore(from) ? from : start;
        final rangeEnd = end.isAfter(to) ? to : end;
        totalLeaveDays += rangeEnd.difference(rangeStart).inDays + 1;
      }
      return totalLeaveDays;
    }
    throw Exception('Không thể lấy số ngày nghỉ phép');
  }
}

class AttendanceSummaryScreen extends StatefulWidget {
  final String token;
  final String? employeeId;
  final String? employeeName;

  const AttendanceSummaryScreen({
    Key? key,
    required this.token,
    this.employeeId,
    this.employeeName,
  }) : super(key: key);

  @override
  _AttendanceSummaryScreenState createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  late AttendanceService _service;
  List<Attendance> _attendances = [];
  String? employeeId;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();

  int _workingDays = 0;
  int _overtimeDays = 0;
  int _leaveDays = 0;

  bool _isLoading = false;

  // Định nghĩa hằng số màu ở cấp class
  static const primaryColor = Color(0xFFFF9800); // Cam đậm
  static const accentColor = Color(0xFFFFB300); // Cam nhạt
  static const textColor = Color(0xFF212121); // Đen đậm
  static const subTextColor = Color(0xFF757575); // Xám

  @override
  void initState() {
    super.initState();
    _service = AttendanceService(token: widget.token);
    _fetchEmployeeIdAndLoadData();
  }

  Future<void> _fetchEmployeeIdAndLoadData() async {
    setState(() => _isLoading = true);

    try {
      // Nếu HR truyền employeeId → dùng luôn
      if (widget.employeeId != null) {
        employeeId = widget.employeeId!;
        await _loadAttendances();
        await _loadSummaryInDateRange();
        return;
      }

      // Nếu không thì giải mã từ token như cũ
      final parts = widget.token.split('.');
      final payload = base64.normalize(parts[1]);
      final decoded = json.decode(utf8.decode(base64.decode(payload)));
      final userId = decoded['userId'] ?? decoded['sub'];

      final res = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        employeeId = res.body.trim();
        await _loadAttendances();
        await _loadSummaryInDateRange();
      } else {
        _showError('Không thể lấy employeeId từ server');
      }
    } catch (e) {
      _showError('Lỗi khi lấy employeeId: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendances() async {
    if (employeeId == null) return;

    setState(() => _isLoading = true);
    try {
      final formattedFrom = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedTo = DateFormat('yyyy-MM-dd').format(toDate);

      final list = await _service.getAttendancesByEmployeeAndDateRange(
        employeeId: employeeId!,
        fromDate: formattedFrom,
        toDate: formattedTo,
      );
      list.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

      setState(() => _attendances = list);
    } catch (e) {
      _showError("❌ ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSummaryInDateRange() async {
    if (employeeId == null) return;

    final formattedFrom = DateFormat('yyyy-MM-dd').format(fromDate);
    final formattedTo = DateFormat('yyyy-MM-dd').format(toDate);

    try {
      final working = await _service.getTotalWorkingDays(
        employeeId: employeeId!,
        fromDate: formattedFrom,
        toDate: formattedTo,
      );

      final ot = await _service.getTotalOvertimeDays(
        employeeId: employeeId!,
        fromDate: formattedFrom,
        toDate: formattedTo,
      );

      final leave = await _service.getTotalLeaveDays(
        employeeId: employeeId!,
        fromDate: formattedFrom,
        toDate: formattedTo,
      );

      setState(() {
        _workingDays = working;
        _overtimeDays = ot;
        _leaveDays = leave;
      });
    } catch (e) {
      _showError("❌ Lỗi khi tải tổng hợp: ${e.toString()}");
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.getRangeByIndex(1, 1).setText('BÁO CÁO CHẤM CÔNG');
      sheet.getRangeByIndex(1, 1, 1, 4).merge();

      final headers = ['Mã NV', 'Ngày', 'Giờ làm', 'Trạng thái'];
      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(2, i + 1).setText(headers[i]);
      }

      for (var i = 0; i < _attendances.length; i++) {
        final att = _attendances[i];
        sheet.getRangeByIndex(i + 3, 1).setText(att.employeeId);
        sheet
            .getRangeByIndex(i + 3, 2)
            .setText(DateFormat('dd/MM/yyyy').format(att.attendanceDate));
        sheet.getRangeByIndex(i + 3, 3).setNumber(att.totalHours);
        sheet.getRangeByIndex(i + 3, 4).setText(att.status);
      }

      final dir = await getDownloadsDirectory();
      final path = '${dir?.path}/bao_cao_cham_cong.xlsx';
      await File(path).writeAsBytes(workbook.saveAsStream());
      workbook.dispose();
      _showSuccess('✅ Đã lưu file tại: $path');
    } catch (e) {
      _showError('Lỗi xuất file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employeeName != null
              ? 'Tổng hợp - ${widget.employeeName}'
              : 'Tổng hợp chấm công',
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
        onRefresh: () async {
          await _loadAttendances();
          await _loadSummaryInDateRange();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tổng hợp
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '📊 Tổng hợp trong khoảng thời gian đã chọn:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('✅', 'Ngày công', _workingDays),
                          _buildSummaryItem('⏱️', 'OT', _overtimeDays),
                          _buildSummaryItem('🛌', 'Nghỉ phép', _leaveDays),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Chọn ngày
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      label: 'Từ ngày',
                      date: fromDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData(
                              primaryColor: primaryColor,
                              colorScheme: ColorScheme.light(
                                primary: primaryColor,
                                onPrimary: Colors.white,
                              ),
                              textTheme: TextTheme(
                                bodyMedium: TextStyle(color: textColor),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() => fromDate = picked);
                          await _loadAttendances();
                          await _loadSummaryInDateRange();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("→", style: TextStyle(color: primaryColor)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateButton(
                      label: 'Đến ngày',
                      date: toDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: toDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData(
                              primaryColor: primaryColor,
                              colorScheme: ColorScheme.light(
                                primary: primaryColor,
                                onPrimary: Colors.white,
                              ),
                              textTheme: TextTheme(
                                bodyMedium: TextStyle(color: textColor),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() => toDate = picked);
                          await _loadAttendances();
                          await _loadSummaryInDateRange();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Export
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Xuất Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                '📝 Danh sách chấm công:',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _attendances.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendances.length,
                itemBuilder: (context, index) {
                  final att = _attendances[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accentColor,
                        child: Text(
                          att.employeeId.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        att.employeeId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(DateFormat('dd/MM/yyyy').format(att.attendanceDate)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(att.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(
                        '${att.totalHours}h',
                        style: const TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String icon, String label, int count) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: subTextColor)),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      icon: Icon(Icons.date_range, color: primaryColor),
      label: Text(
        '$label: ${DateFormat('dd/MM/yyyy').format(date)}',
        style: TextStyle(color: textColor),
      ),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: accentColor.withOpacity(0.1), // Nền nhạt để tạo sự hài hòa
        side: BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}