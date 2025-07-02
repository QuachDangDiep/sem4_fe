import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/hr/Staff/staff.dart';
//import 'package:sem4_fe/ui/hr/timekeeping/Timekeeping.dart';
import 'package:intl/intl.dart';

class QRAttendanceModel {
  final String qrId;
  final String employeeName;
  final String employeeId;
  final String status;
  final String attendanceMethod;
  final String faceRecognitionImage;
  final DateTime? timestamp;

  QRAttendanceModel({
    required this.qrId,
    required this.employeeName,
    required this.employeeId,
    required this.status,
    required this.attendanceMethod,
    required this.faceRecognitionImage,
    this.timestamp,
  });

  factory QRAttendanceModel.fromJson(Map<String, dynamic> json) {
    return QRAttendanceModel(
      qrId: json['qrId'] ?? '',
      employeeName: json['employee']?['fullName'] ?? '',
      employeeId: json['employee']?['employeeCode'] ?? '',
      status: json['status'] ?? '',
      attendanceMethod: json['attendanceMethod'] ?? '',
      faceRecognitionImage: json['faceRecognitionImage'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }
}

class HomeHRPage extends StatefulWidget {
  final String username;
  final String token;

  const HomeHRPage({super.key, required this.username, required this.token});

  @override
  State<HomeHRPage> createState() => _HomeHRPageState();
}

class _HomeHRPageState extends State<HomeHRPage> {
  int _selectedIndex = 0;
  final colors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFFFA726),
    const Color(0xFFFB8C00),
    const Color(0xFFEF6C00),
  ];


  // void _onItemTapped(int index) {
  //   if (index == _selectedIndex) return;
  //   setState(() => _selectedIndex = index);
  //   switch (index) {
  //     case 0:
  //       break;
  //     case 1:
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //             builder: (_) =>
  //                 StaffScreen(username: widget.username, token: widget.token)),
  //       );
  //       break;
  //     case 2:
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //             builder: (_) => TimekeepingScreen(
  //                 username: widget.username, token: widget.token)),
  //       );
  //       break;
  //     case 3:
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Chức năng Báo cáo đang được phát triển')),
  //       );
  //       break;
  //     case 4:
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //             builder: (_) => HrSettingsPage(
  //                 username: widget.username, token: widget.token)),
  //       );
  //       break;
  //   }
  // }
  Future<String?> getUserRoleId() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/roles'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final roles = jsonDecode(response.body)['result'] ?? [];
        return roles.firstWhere((role) => role['roleName'] == 'User', orElse: () => null)?['roleId'];
      }
    } catch (e) {
      print('Error fetching roles: $e');
    }
    return null;
  }

  Future<List<UserResponse>> fetchUsers({String? status}) async {
    final roleId = await getUserRoleId();
    if (roleId == null) throw Exception('User role not found');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/users${status != null ? '?status=$status' : ''}'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['result'] ?? [])
            .map<UserResponse>((json) => UserResponse.fromJson(json))
            .where((user) => user.role == roleId)
            .toList();
      }
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<int> fetchTotalEmployees() async {
    final users = await fetchUsers();
    return users.length;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffScreen(username: widget.username, token: widget.token)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TimekeepingScreen(username: widget.username, token: widget.token)),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chức năng Báo cáo đang được phát triển')),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HrSettingsPage(username: widget.username, token: widget.token)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: colors[1],
        elevation: 2,
        centerTitle: true,
        title: const Text('Quản lý Nhân sự',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TodayAttendanceSection(
                  token: widget.token, colors: colors),
            ),
            const SizedBox(height: 24),
            AttendanceRatio(colors: colors),
          ],
        ),
      )
          : Center(
        child: Text(
          'Chức năng đang được phát triển...',
          style: TextStyle(color: colors[2], fontSize: 16),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: colors[3],
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
       // onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Nhân viên'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint_outlined), label: 'Chấm công'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

class AttendanceRatio extends StatelessWidget {
  final List<Color> colors;
  const AttendanceRatio({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final data = {'Có mặt': 82, 'Nghỉ phép': 8, 'Nghỉ không phép': 10};
    final total = data.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors[0].withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: colors[0].withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tỷ lệ đi làm',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: colors[3], fontSize: 16)),
          const SizedBox(height: 12),
          ...data.entries.map((e) => AttendanceBar(
            label: e.key,
            percentage: (e.value / total) * 100,
            color: e.key == 'Có mặt'
                ? Colors.green
                : (e.key == 'Nghỉ phép' ? Colors.orange : Colors.red),
          )),
        ],
      ),
    );
  }
}

class AttendanceBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const AttendanceBar(
      {super.key,
        required this.label,
        required this.percentage,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                    height: 18,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10))),
                Container(
                    height: 18,
                    width: MediaQuery.of(context).size.width * 0.6 * (percentage / 100),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
          Expanded(
              flex: 1,
              child: Text('${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class TodayAttendanceSection extends StatelessWidget {
  final String token;
  final List<Color> colors;

  const TodayAttendanceSection(
      {super.key, required this.token, required this.colors});

  Future<List<QRAttendanceModel>> fetchAttendanceList() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.activeQrAttendanceUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is List) {
          final today = DateTime.now().toIso8601String().split('T')[0];
          return jsonData
              .map((item) => QRAttendanceModel.fromJson(item))
              .where((item) =>
          (item.status == 'CheckIn' || item.status == 'CheckOut') &&
              item.timestamp != null &&
              item.timestamp!.toIso8601String().split('T')[0] == today)
              .toList()
            ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
        } else {
          throw Exception('Dữ liệu không đúng định dạng danh sách');
        }
      } else {
        throw Exception('Lỗi khi tải dữ liệu chấm công: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải dữ liệu chấm công: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Đã chấm công hôm nay',
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 18, color: colors[3])),
        const SizedBox(height: 12),
        FutureBuilder<List<QRAttendanceModel>>(
          future: fetchAttendanceList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Lỗi: ${snapshot.error}',
                  style: TextStyle(color: colors[2], fontSize: 16));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('Chưa có ai chấm công hôm nay',
                  style: TextStyle(color: colors[2], fontSize: 16));
            }

            final attendances = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendances.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final emp = attendances[index];
                final isPresent = emp.status == 'CheckIn';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: emp.faceRecognitionImage.isNotEmpty
                        ? MemoryImage(base64Decode(emp.faceRecognitionImage))
                        : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
                    radius: 24,
                  ),
                  title: Text(emp.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  subtitle: Text(
                    'Mã NV: ${emp.employeeId} - ${emp.attendanceMethod}${emp.timestamp != null ? ' - ${DateFormat('HH:mm dd/MM').format(emp.timestamp!)}' : ''}',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          isPresent ? Icons.login : Icons.logout,
                          color: isPresent ? Colors.green : Colors.blue,
                          size: 20),
                      Text(
                        emp.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPresent
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}