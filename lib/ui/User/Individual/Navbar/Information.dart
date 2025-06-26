import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/Service/Constants.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String token;

  const PersonalInfoScreen({Key? key, required this.token}) : super(key: key);

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  Future<Map<String, dynamic>> _employeeInfo = Future.value({});
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeInfo();
  }

  Future<void> _fetchEmployeeInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Token không tồn tại');

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) throw Exception('Không tìm thấy userId trong token');

      final idRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (idRes.statusCode != 200) throw Exception('Không lấy được employeeId');

      final employeeId = idRes.body.trim();

      final infoRes = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (infoRes.statusCode != 200) throw Exception('Không lấy được thông tin nhân viên');

      final data = json.decode(infoRes.body);
      setState(() {
        _employeeInfo = Future.value(data);
      });
    } catch (e) {
      setState(() {
        _employeeInfo = Future.error('Lỗi khi truy xuất thông tin nhân viên: ${e.toString()}');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Fix lỗi ép kiểu tại đây
  String _getGenderText(dynamic genderCode) {
    int? code;
    if (genderCode is String) {
      code = int.tryParse(genderCode);
    } else if (genderCode is int) {
      code = genderCode;
    }

    switch (code) {
      case 0:
        return 'Nữ';
      case 1:
        return 'Nam';
      case 2:
        return 'Khác';
      default:
        return 'Không xác định';
    }
  }

  String _getStatusText(dynamic statusCode) {
    int? code;
    if (statusCode is String) {
      code = int.tryParse(statusCode);
    } else if (statusCode is int) {
      code = statusCode;
    }

    switch (code) {
      case 0:
        return 'Đang làm việc';
      case 1:
        return 'Đã nghỉ việc';
      case 2:
        return 'Tạm nghỉ';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Không có thông tin';
    try {
      DateTime d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  IconData _getIconForField(String label) {
    switch (label) {
      case 'Họ tên':
        return Icons.person;
      case 'Mã nhân viên':
        return Icons.badge;
      case 'Phòng ban':
        return Icons.apartment;
      case 'Chức vụ':
        return Icons.work_outline;
      case 'Giới tính':
        return Icons.transgender;
      case 'Ngày sinh':
        return Icons.cake;
      case 'Số điện thoại':
        return Icons.phone;
      case 'Địa chỉ':
        return Icons.location_on;
      case 'Ngày vào làm':
        return Icons.calendar_today;
      case 'Trạng thái':
        return Icons.check_circle_outline;
      case 'Ngày tạo hồ sơ':
        return Icons.create;
      case 'Ngày cập nhật':
        return Icons.update;
      default:
        return Icons.info;
    }
  }

  Widget _buildHeader(Map<String, dynamic> employeeData) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.orange.shade100,
          backgroundImage: (employeeData['img'] ?? '').toString().isNotEmpty
              ? NetworkImage(employeeData['img'])
              : null,
          child: (employeeData['img'] ?? '').toString().isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          employeeData['fullName'] ?? 'Không có thông tin',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          'Mã NV: ${employeeData['employeeId'] ?? '---'}',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const Divider(height: 30, thickness: 1),
      ],
    );
  }

  Widget _buildUserInfo(Map<String, String> data) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        String label = data.keys.elementAt(index);
        String value = data[label]!;
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[50],
              child: Icon(_getIconForField(label), color: Colors.orange),
            ),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(value),
          ),
        );
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 50, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchEmployeeInfo,
            child: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          )
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('Không tìm thấy dữ liệu nhân viên'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _fetchEmployeeInfo,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _employeeInfo,
        builder: (context, snapshot) {
          if (_isLoading) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _buildError(snapshot.error.toString());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmpty();

          final data = snapshot.data!;
          final department = data['department']?['departmentName'] ?? 'Không có thông tin';
          final position = data['position']?['positionName'] ?? 'Không có thông tin';
          final gender = _getGenderText(data['gender']);
          final status = _getStatusText(data['status']);

          final Map<String, String> infoMap = {
            'Họ tên': data['fullName']?.toString() ?? '',
            'Mã nhân viên': data['employeeId']?.toString() ?? '',
            'Phòng ban': department.toString(),
            'Chức vụ': position.toString(),
            'Giới tính': gender,
            'Ngày sinh': _formatDate(data['dateOfBirth']),
            'Số điện thoại': data['phone']?.toString() ?? '',
            'Địa chỉ': data['address']?.toString() ?? '',
            'Ngày vào làm': _formatDate(data['hireDate']),
            'Trạng thái': status,
            'Ngày tạo hồ sơ': _formatDate(data['createdAt']),
            'Ngày cập nhật': _formatDate(data['updatedAt']),
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildHeader(data),
                _buildUserInfo(infoMap),
              ],
            ),
          );
        },
      ),
    );
  }
}
