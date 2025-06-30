import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/ui/hr/Staff/staff.dart';
import 'package:sem4_fe/ui/hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/hr/home/HomeHr.dart';

class QRAttendanceModel {
  final String qrId;
  final String employeeName;
  final String employeeId;
  final String status;
  final String attendanceMethod;
  final String faceRecognitionImage;

  QRAttendanceModel({
    required this.qrId,
    required this.employeeName,
    required this.employeeId,
    required this.status,
    required this.attendanceMethod,
    required this.faceRecognitionImage,
  });

  factory QRAttendanceModel.fromJson(Map<String, dynamic> json) {
    return QRAttendanceModel(
      qrId: json['qrId'],
      employeeName: json['employee']?['fullName'] ?? '',
      employeeId: json['employee']?['employeeCode'] ?? '',
      status: json['status'] ?? '',
      attendanceMethod: json['attendanceMethod'] ?? '',
      faceRecognitionImage: json['faceRecognitionImage'] ?? '',
    );
  }
}

class TimekeepingScreen extends StatefulWidget {
  final String username;
  final String token;

  const TimekeepingScreen({Key? key, required this.username, required this.token})
      : super(key: key);

  @override
  State<TimekeepingScreen> createState() => _TimekeepingScreenState();
}

class _TimekeepingScreenState extends State<TimekeepingScreen> {
  late Future<List<QRAttendanceModel>> futureAttendances;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    futureAttendances = fetchAttendanceList();
  }

  Future<List<QRAttendanceModel>> fetchAttendanceList() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/qrattendance/today'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((item) => QRAttendanceModel.fromJson(item)).toList();
    } else {
      throw Exception('Lỗi khi tải dữ liệu chấm công');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = HomeHRPage(username: widget.username, token: widget.token);
        break;
      case 1:
        nextPage = StaffScreen(username: widget.username, token: widget.token);
        break;
      case 2:
        nextPage = TimekeepingScreen(username: widget.username, token: widget.token);
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chức năng Báo cáo đang được phát triển')),
        );
        return;
      case 4:
        nextPage = HrSettingsPage(username: widget.username, token: widget.token);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm công hôm nay'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<QRAttendanceModel>>(
        future: futureAttendances,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có dữ liệu chấm công'));
          }

          final employees = snapshot.data!;
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: emp.faceRecognitionImage.isNotEmpty
                        ? MemoryImage(base64Decode(emp.faceRecognitionImage))
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    radius: 24,
                  ),
                  title: Text(emp.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mã NV: \${emp.employeeId}'),
                      Text('Hình thức: \${emp.attendanceMethod}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: emp.status == 'Present' || emp.status == 'CheckIn'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emp.status, style: const TextStyle(fontSize: 12, color: Colors.black)),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Nhân viên'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'Chấm công'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
