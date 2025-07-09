import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String token;
  const AttendanceHistoryScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  Map<String, List<Map<String, dynamic>>> attendanceByDate = {}; // yyyy-MM-dd: list of records
  String? employeeId;
  String? _errorMessage;
  int selectedMonth = DateTime.now().month;


  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    try {
      final token = widget.token;
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['userId'];

      final response = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          employeeId = response.body.replaceAll('"', ''); // clean quotes if any
        });
        await fetchAttendanceData(employeeId!);
        print (employeeId);
      } else {
        throw Exception('Không lấy được employeeId từ userId');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi lấy employeeId: ${e.toString()}';
      });
      print("❌ $_errorMessage");
    }
  }


  Future<void> fetchAttendanceData(String empId) async {
    final url = Constants.qrAttendancesByEmployeeUrl(empId);
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}', // ĐỪNG QUÊN TOKEN
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Data nhận được: $data"); // Debug dữ liệu

        Map<String, List<Map<String, dynamic>>> temp = {};

        for (var item in data) {
          final date = item['attendanceDate']; // ⚠️ dùng đúng key JSON
          final scanTime = item['scanTime'];   // ⚠️ đúng tên trường

          if (!temp.containsKey(date)) temp[date] = [];
          temp[date]!.add({
            'status': item['status'],
            'scan_time': scanTime,
          });
        }

        setState(() {
          attendanceByDate = temp;
        });
      } else {
        print('❌ Lỗi khi tải dữ liệu chấm công: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi tải dữ liệu chấm công: $e');
    }
  }


  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token không hợp lệ');
    }

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return json.decode(payload);
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Absent':
        return Colors.red;
      case 'On Leave':
        return Colors.blue;
      case 'CheckIn':
      case 'CheckOut':
        return Colors.purpleAccent;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget buildDayBox(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final records = attendanceByDate[dateStr] ?? [];

    String? earlyStatus;
    String? lateStatus;

    if (records.isNotEmpty) {
      records.sort((a, b) => a['scan_time'].compareTo(b['scan_time']));
      earlyStatus = records.first['status'];
      lateStatus = records.last['status'];
    }

    return Tooltip(
      message:
      '${DateFormat('dd/MM/yyyy').format(date)}\nSớm: ${earlyStatus ?? "Không có"}\nMuộn: ${lateStatus ?? "Không có"}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: getStatusColor(earlyStatus),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: getStatusColor(lateStatus),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCalendarMonth(int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDay = DateTime(year, month, 1);
    final firstWeekday = firstDay.weekday % 7; // 1=Mon, 7=Sun → 0=Sun
    final totalCells = daysInMonth + firstWeekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tháng $month',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final day in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ((totalCells / 7).ceil()) * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayIndex = index - firstWeekday;
            if (dayIndex < 0 || dayIndex >= daysInMonth) {
              return Container(); // ô trống
            }
            final date = DateTime(year, month, dayIndex + 1);
            return buildDayBox(date);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendBox('Present', Colors.green),
        _legendBox('Late', Colors.orange),
        _legendBox('Absent', Colors.red),
        _legendBox('On Leave', Colors.blue),
        _legendBox('CheckIn/Out', Colors.purpleAccent),
        _legendBox('No Data', Colors.grey.shade200),
      ],
    );
  }

  Widget _legendBox(String label, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 6,
      ),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử chấm công $currentYear',style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bộ chọn tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn tháng:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedMonth,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                      items: List.generate(12, (index) {
                        int month = index + 1;
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text('Tháng $month'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedMonth = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chú thích màu
            _buildLegend(),
            const SizedBox(height: 12),

            // Lịch hiển thị của tháng đã chọn
            Expanded(
              child: SingleChildScrollView(
                child: buildCalendarMonth(DateTime.now().year, selectedMonth),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
