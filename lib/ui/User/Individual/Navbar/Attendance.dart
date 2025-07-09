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
        title: const Text('Tổng hợp chấm công'),
        backgroundColor: const Color(0xFFF57C00),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAttendances,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Từ: ${DateFormat('dd/MM/yyyy').format(fromDate)}'),
                      Text('Đến: ${DateFormat('dd/MM/yyyy').format(toDate)}'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.date_range),
                        tooltip: 'Từ ngày',
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fromDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => fromDate = picked);
                            await _loadAttendances();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.date_range_outlined),
                        tooltip: 'Đến ngày',
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: toDate,
                            firstDate: fromDate,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => toDate = picked);
                            await _loadAttendances();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trạng thái:'),
                  DropdownButton<String>(
                    value: selectedStatus ?? 'All',
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
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.download),
                label: const Text('Xuất Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Danh sách chấm công:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendances.length,
                itemBuilder: (context, index) {
                  final att = _attendances[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF57C00),
                        child: Text(att.employeeId.substring(0, 2), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(att.employeeId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Ngày: ${DateFormat('dd/MM/yyyy').format(att.attendanceDate)}\nTrạng thái: ${att.status}',
                      ),
                      trailing: Text('${att.totalHours}h',
                          style: const TextStyle(color: Color(0xFFEF6C00), fontWeight: FontWeight.bold)),
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
