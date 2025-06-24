import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'dart:io';

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

  Future<List<Attendance>> getAttendances() async {
    final response = await http.get(Uri.parse(Constants.dancesUrl),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => Attendance.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load attendances');
  }

  Future<String> generateSummary(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await http.post(
      Uri.parse(Constants.summaryUrl(formattedDate)),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to generate summary');
  }

  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}

// 2. Màn hình chính
class AttendanceSummaryScreen extends StatefulWidget {
  final String token;

  const AttendanceSummaryScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _AttendanceSummaryScreenState createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  late AttendanceService _service;
  List<Attendance> _attendances = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _service = AttendanceService(token: widget.token);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _attendances = await _service.getAttendances();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);
    try {
      // Tạo file Excel - sử dụng alias xlsio
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // Thêm dữ liệu
      sheet.getRangeByIndex(1, 1).setText('BÁO CÁO CHẤM CÔNG');
      sheet.getRangeByIndex(1, 1, 1, 4).merge();

      // Tiêu đề cột
      final headers = ['Mã NV', 'Ngày', 'Giờ làm', 'Trạng thái'];
      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(2, i + 1).setText(headers[i]);
      }

      // Dữ liệu
      for (var i = 0; i < _attendances.length; i++) {
        final att = _attendances[i];
        sheet.getRangeByIndex(i + 3, 1).setText(att.employeeId);
        sheet.getRangeByIndex(i + 3, 2).setText(
            DateFormat('dd/MM/yyyy').format(att.attendanceDate));
        sheet.getRangeByIndex(i + 3, 3).setNumber(att.totalHours);
        sheet.getRangeByIndex(i + 3, 4).setText(att.status);
      }

      // Lưu file
      final dir = await getDownloadsDirectory();
      final path = '${dir?.path}/bao_cao_cham_cong.xlsx';
      await File(path).writeAsBytes(workbook.saveAsStream());
      workbook.dispose();

      _showSuccess('Đã lưu file tại: $path');
    } catch (e) {
      _showError('Lỗi xuất file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng hợp chấm công'),
        backgroundColor: Color(0xFFF57C00), // Cam đậm
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn ngày
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ngày: ${DateFormat('dd/MM/yyyy').format(
                            _selectedDate)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 20),
                      label: const Text('Chọn ngày'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8F00), // Cam sáng
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nút xuất báo cáo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Xuất báo cáo Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFB300),
                      // Cam vàng sáng
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Danh sách chấm công:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFF57C00), // Cam đậm
                          child: Text(
                            att.employeeId.substring(0, 2),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          att.employeeId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Ngày: ${DateFormat('dd/MM/yyyy').format(
                              att.attendanceDate)}\nTrạng thái: ${att.status}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Text(
                          '${att.totalHours}h',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFEF6C00), // Cam nâu đậm
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
      ),
    );
  }
}