import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  List<dynamic> attendanceList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(Constants.activeQrAttendanceUrl));

      if (response.statusCode == 200) {
        setState(() {
          attendanceList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance records');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteAttendance(String qrId) async {
    final url = Constants.qrAttendanceDetailUrl(qrId);
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thành công')),
      );
      fetchAttendance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thất bại')),
      );
    }
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chấm công (HR)'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceList.isEmpty
          ? const Center(child: Text('Không có dữ liệu chấm công'))
          : ListView.builder(
        itemCount: attendanceList.length,
        itemBuilder: (context, index) {
          final item = attendanceList[index];
          final employee = item['employee'];
          final employeeName =
              "${employee?['firstName'] ?? ''} ${employee?['lastName'] ?? ''}";

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              color: const Color(0xFFF7F7F7), // nền xám nhẹ
              shadowColor: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            employeeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: const Text('Bạn có chắc muốn xóa bản ghi này không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await deleteAttendance(item['qrId']);
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    buildInfoRow(Icons.calendar_today, 'Ngày chấm công:',
                        formatDate(item['attendanceDate'] ?? '')),
                    const SizedBox(height: 8),
                    buildInfoRow(Icons.badge, 'Phương thức:', item['attendanceMethod'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    buildInfoRow(Icons.info_outline, 'Trạng thái:', item['status'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildInfoRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.blueGrey),
      const SizedBox(width: 10),
      Expanded(
        child: RichText(
          text: TextSpan(
            text: '$label ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

