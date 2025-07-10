import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/Hr/Staff/staff.dart';
import 'package:sem4_fe/ui/Hr/Timekeeping/Timekeeping.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/ui/Hr/Leaverquest/Leaverequestpase.dart';

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
      qrId: json['qrId']?.toString() ?? '',
      employeeName: json['employee']?['fullName']?.toString() ?? 'Unknown',
      employeeId: json['employee']?['employeeCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      attendanceMethod: json['attendanceMethod']?.toString() ?? '',
      faceRecognitionImage: json['faceRecognitionImage']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }
}

class UserResponse {
  final String userId;
  final String username;
  final String email;
  final String role;
  final String status;

  UserResponse({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
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
  String? employeeId;
  bool isLoading = true;
  Timer? _checkInTimer;
  String? _lastCheckInKey;

  @override
  void initState() {
    super.initState();
    print('Initializing HomeHRPage with username: ${widget.username}, token: ${widget.token}');
    _initializeData();
    _startCheckInPolling();
  }

  Future<void> _initializeData() async {
    try {
      print('Starting initialization');
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('Attempt $attempt to load employeeId');
        await _loadEmployeeId();
        if (employeeId != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }

      if (employeeId == null) {
        print('Failed to load employeeId after 3 attempts');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải employeeId. Vui lòng đăng nhập lại.')),
        );
        return;
      }

      await _notifyCheckIns();
      setState(() {
        isLoading = false;
      });
      print('Initialization completed successfully');
    } catch (e) {
      print('Error in _initializeData: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi tạo dữ liệu: $e')),
      );
    }
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedEmployeeId = prefs.getString('employeeId');
    if (storedEmployeeId != null && storedEmployeeId.isNotEmpty) {
      setState(() {
        employeeId = storedEmployeeId;
      });
      print('Loaded employeeId from SharedPreferences: $employeeId');
      return;
    }

    try {
      final decoded = JwtDecoder.decode(widget.token);
      print('JWT token payload: $decoded');
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) {
        throw Exception('Không tìm thấy userId trong token');
      }
      print('Decoded userId from token: $userId');

      final url = Constants.employeeIdByUserIdUrl(userId);
      print('Fetching employeeId from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));

      print('EmployeeId API response status: ${response.statusCode}');
      print('EmployeeId API response body: ${response.body}');

      if (response.statusCode == 200) {
        final fetchedEmployeeId = response.body.trim();
        if (fetchedEmployeeId.isNotEmpty) {
          await prefs.setString('employeeId', fetchedEmployeeId);
          setState(() {
            employeeId = fetchedEmployeeId;
          });
          print('Fetched and saved employeeId: $fetchedEmployeeId');
        } else {
          throw Exception('Không tìm thấy employeeId từ API');
        }
      } else {
        throw Exception('Lỗi khi lấy employeeId: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading employeeId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải employeeId: $e')),
      );
    }
  }

  Future<void> _startCheckInPolling() async {
    print('Starting check-in polling');
    final prefs = await SharedPreferences.getInstance();
    _checkInTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        print('Widget not mounted, cancelling polling');
        timer.cancel();
        return;
      }
      final value = prefs.getString('lastCheckIn');
      if (value != null && value != _lastCheckInKey) {
        try {
          final checkIn = jsonDecode(value);
          final employeeName = checkIn['employeeName']?.toString() ?? 'Unknown';
          final employeeId = checkIn['employeeId']?.toString() ?? 'N/A';
          final timestamp = checkIn['timestamp']?.toString() ?? 'N/A';
          print('New check-in detected: $employeeName ($employeeId) at $timestamp');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$employeeName ($employeeId) đã chấm công vào lúc $timestamp'),
              duration: const Duration(seconds: 5),
            ),
          );
          _lastCheckInKey = value;
          setState(() {}); // Refresh attendance list
        } catch (e) {
          print('Error processing check-in: $e');
        }
      }
    });
  }

  Future<void> _notifyCheckIns() async {
    try {
      final checkIns = await _fetchCheckIns();
      if (checkIns.isNotEmpty && mounted) {
        final message = checkIns
            .map((emp) =>
        '${emp.employeeName} (${emp.employeeId}) - ${DateFormat('HH:mm').format(emp.timestamp!)}')
            .join('\n');
        print('Notifying check-ins:\n$message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nhân viên đã chấm công hôm nay:\n$message'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        print('No check-ins found for today');
      }
    } catch (e) {
      print('Error notifying check-ins: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thông báo chấm công: $e')),
        );
      }
    }
  }

  Future<List<QRAttendanceModel>> _fetchCheckIns() async {
    try {
      print('Fetching check-ins from: ${Constants.activeQrAttendanceUrl}');
      final response = await http.get(
        Uri.parse(Constants.activeQrAttendanceUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      print('Check-in API response status: ${response.statusCode}');
      print('Check-in API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          final today = DateTime.now().toIso8601String().split('T')[0];
          return jsonData
              .map((item) => QRAttendanceModel.fromJson(item))
              .where((item) =>
          item.status == 'CheckIn' &&
              item.timestamp != null &&
              item.timestamp!.toIso8601String().split('T')[0] == today)
              .toList()
            ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
        } else {
          throw Exception('Dữ liệu không đúng định dạng danh sách');
        }
      } else {
        throw Exception('Lỗi khi tải dữ liệu chấm công: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching check-ins: $e');
      throw Exception('Lỗi khi tải dữ liệu chấm công: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == _selectedIndex) return;
    print('Bottom navigation tapped: index $index');
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StaffScreen(username: widget.username, token: widget.token),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkScheduleInfoListScreen(username: widget.username,token: widget.token),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveRequestPage(username: widget.username,token: widget.token),
          ),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HrSettingsPage(username: widget.username, token: widget.token),
          ),
        );
        break;
    }
  }

  Future<String?> getUserRoleId() async {
    try {
      print('Fetching roles from: http://10.0.2.2:8080/api/roles');
      final response = await http.get(
        Uri.parse(Constants.rolesUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      print('Roles API response status: ${response.statusCode}');
      print('Roles API response body: ${response.body}');

      if (response.statusCode == 200) {
        final roles = jsonDecode(response.body)['result'] ?? [];
        final userRole = roles.firstWhere(
              (role) => role['roleName']?.toString().toLowerCase() == 'user',
          orElse: () => null,
        );
        return userRole?['roleId']?.toString();
      }
      throw Exception('Failed to fetch roles: ${response.statusCode}');
    } catch (e) {
      print('Error fetching roles: $e');
      return null;
    }
  }

  Future<List<UserResponse>> fetchUsers({String? status}) async {
    final roleId = await getUserRoleId();
    if (roleId == null) {
      print('Error: User role ID not found');
      throw Exception('Không tìm thấy roleId của User');
    }
    try {
      final url = '${Constants.baseUrl}/api/users${status != null ? '?status=$status' : ''}';
      print('Fetching users from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      print('Users API response status: ${response.statusCode}');
      print('Users API response body: ${response.body}');

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body)['result'] ?? [];
        return users
            .map<UserResponse>((json) => UserResponse.fromJson(json))
            .where((user) => user.role == roleId)
            .toList();
      }
      throw Exception('Failed to load users: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Lỗi khi tải danh sách người dùng: $e');
    }
  }

  Future<int> fetchTotalEmployees() async {
    try {
      final users = await fetchUsers();
      print('Total employees fetched: ${users.length}');
      return users.length;
    } catch (e) {
      print('Error fetching total employees: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    print('Disposing HomeHRPage, cancelling check-in timer');
    _checkInTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
        backgroundColor: colors[1],
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Tổng quan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
      )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 0: Tổng quan
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: TodayAttendanceSection(
                    token: widget.token,
                    colors: colors,
                    employeeId: employeeId,
                  ),
                ),
                const SizedBox(height: 24),
                AttendanceRatio(colors: colors),
              ],
            ),
          ),

          // Tab 1: Nhân viên
          StaffScreen(username: widget.username, token: widget.token),

          // Tab 2: Ca làm
          WorkScheduleInfoListScreen(username: widget.username, token: widget.token),

          // Tab 3: Báo cáo (placeholder)
          LeaveRequestPage(username: widget.username, token: widget.token),

          // Tab 4: Cài đặt
          HrSettingsPage(username: widget.username, token: widget.token),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: colors[3],
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Nhân viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Ca làm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page_outlined),
            label: 'Đơn xin nghỉ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            label: 'Quản lý',
          ),
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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tỷ lệ đi làm',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors[3],
              fontSize: 16,
            ),
          ),
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

  const AttendanceBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  height: 18,
                  width: MediaQuery.of(context).size.width * 0.6 * (percentage / 100),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayAttendanceSection extends StatelessWidget {
  final String token;
  final List<Color> colors;
  final String? employeeId;

  const TodayAttendanceSection({
    super.key,
    required this.token,
    required this.colors,
    this.employeeId,
  });

  Future<List<QRAttendanceModel>> fetchAttendanceList() async {
    try {
      print('Fetching attendance from: ${Constants.activeQrAttendanceUrl}');
      final response = await http.get(
        Uri.parse(Constants.activeQrAttendanceUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      print('Attendance API response status: ${response.statusCode}');
      print('Attendance API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          final today = DateTime.now().toIso8601String().split('T')[0];
          return jsonData
              .map((item) => QRAttendanceModel.fromJson(item))
              .where((item) =>
          (item.status == 'CheckIn' || item.status == 'CheckOut') &&
              (employeeId == null || item.employeeId == employeeId) &&
              item.timestamp != null &&
              item.timestamp!.toIso8601String().split('T')[0] == today)
              .toList()
            ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
        } else {
          throw Exception('Dữ liệu không đúng định dạng danh sách');
        }
      } else {
        throw Exception('Lỗi khi tải dữ liệu chấm công: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      throw Exception('Lỗi khi tải dữ liệu chấm công: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Đã chấm công hôm nay',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: colors[3],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<QRAttendanceModel>>(
          future: fetchAttendanceList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('Attendance fetch error: ${snapshot.error}');
              return Text(
                'Lỗi: ${snapshot.error}',
                style: TextStyle(color: colors[2], fontSize: 16),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                'Chưa có ai chấm công hôm nay',
                style: TextStyle(color: colors[2], fontSize: 16),
              );
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
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    radius: 24,
                    onBackgroundImageError: (error, stackTrace) {
                      print('Error loading face recognition image: $error');
                    },
                  ),
                  title: Text(
                    emp.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
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
                        size: 20,
                      ),
                      Text(
                        emp.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPresent ? Colors.green.shade700 : Colors.blue.shade700,
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