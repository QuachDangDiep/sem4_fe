import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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

  Future<List<Attendance>> getAttendancesByEmployeeAndDateRange({
    required String employeeId,
    required String fromDate,
    required String toDate,
    String? status,
  }) async {
    final url = Constants.filterAttendancesUrlWithStatus(
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
    );

    final res = await http.get(Uri.parse(url), headers: _buildHeaders());

    if (res.statusCode == 200) {
      return (json.decode(res.body) as List)
          .map((e) => Attendance.fromJson(e))
          .toList();
    }
    throw Exception('Không thể tải danh sách chấm công theo điều kiện');
  }

  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}

class AttendanceSummaryScreen extends StatefulWidget {
  final String token;

  const AttendanceSummaryScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AttendanceSummaryScreenState createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  late AttendanceService _service;
  List<Attendance> _attendances = [];
  String? employeeId;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();

  String? selectedStatus;
  final List<String> statusOptions = ['All', 'Present', 'Absent', 'Late', 'On Leave'];

  int selectedMonth = DateTime.now().month;

  final List<String> months = List.generate(12, (index) => 'Tháng ${index + 1}');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = AttendanceService(token: widget.token);
    _fetchEmployeeIdAndLoadAttendances();
  }

  Future<void> _fetchEmployeeIdAndLoadAttendances() async {
    setState(() => _isLoading = true);
    try {
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
        status: selectedStatus == null || selectedStatus == 'All' ? null : selectedStatus,
      );

      setState(() => _attendances = list);
    } catch (e) {
      _showError("❌ ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
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
        sheet.getRangeByIndex(i + 3, 2).setText(DateFormat('dd/MM/yyyy').format(att.attendanceDate));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Tổng hợp chấm công', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAttendances,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedMonth,
                                  icon: const Icon(Icons.expand_more_rounded, color: Colors.orange),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: Colors.black, fontSize: 14),
                                  borderRadius: BorderRadius.circular(12),
                                  isExpanded: true,
                                  items: List.generate(12, (index) {
                                    final month = index + 1;
                                    return DropdownMenuItem<int>(
                                      value: month,
                                      child: Text('Tháng $month'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedMonth = value;
                                        final now = DateTime.now();
                                        fromDate = DateTime(now.year, selectedMonth, 1);
                                        toDate = DateTime(now.year, selectedMonth + 1, 0);
                                      });
                                      _loadAttendances();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trạng thái:'),
                          DropdownButton<String>(
                            value: selectedStatus ?? 'All',
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                            items: statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setState(() => selectedStatus = value);
                              await _loadAttendances();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Nút export
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('Xuất Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text('📝 Danh sách chấm công:',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Danh sách chấm công
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendances.length,
                itemBuilder: (context, index) {
                  final att = _attendances[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF57C00),
                        child: Text(
                          att.employeeId.substring(0, 2).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(att.employeeId,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📅 Ngày: ${DateFormat('dd/MM/yyyy').format(att.attendanceDate)}'),
                          Text('📌 Trạng thái: ${att.status}'),
                        ],
                      ),
                      trailing: Text(
                        '${att.totalHours}h',
                        style: const TextStyle(
                          color: Color(0xFFEF6C00),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      isThreeLine: true,
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
}
