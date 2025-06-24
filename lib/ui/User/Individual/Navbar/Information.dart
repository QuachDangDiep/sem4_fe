import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String token;

  const PersonalInfoScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  Future<Map<String, dynamic>> _employeeInfo = Future.value({});
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchEmployeeInfo();
  }

  Future<void> _loadUserIdAndFetchEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    if (_userId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại')),
      );
      return;
    }

    setState(() {
      _employeeInfo = _fetchEmployeeInfo(_userId!);
    });
  }


  Future<Map<String, dynamic>> _fetchEmployeeInfo(String userId) async {
    try {
      print('Bắt đầu lấy thông tin cho userId: $userId');

      // 1. Lấy employeeId
      final employeeIdUrl = Constants.employeeIdByUserIdUrl(userId);
      print('URL lấy employeeId: $employeeIdUrl');

      final employeeIdResponse = await http.get(
        Uri.parse(employeeIdUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Response lấy employeeId: ${employeeIdResponse.statusCode} - ${employeeIdResponse.body}');

      if (employeeIdResponse.statusCode != 200) {
        throw Exception('Không thể lấy employeeId: ${employeeIdResponse.statusCode}');
      }

      final employeeIdData = json.decode(employeeIdResponse.body);
      print('Dữ liệu employeeId nhận được: $employeeIdData');

      // Kiểm tra nhiều trường hợp key có thể có
      final employeeId = employeeIdData['employeeId'] ??
          employeeIdData['id'] ??
          employeeIdData['employee_id'] ??
          employeeIdData['maNhanVien'];

      if (employeeId == null) {
        throw Exception('Không tìm thấy employeeId trong response. Dữ liệu nhận được: $employeeIdData');
      }

      // 2. Lấy thông tin chi tiết nhân viên
      final detailUrl = Constants.employeeDetailUrl(employeeId.toString());
      print('URL lấy thông tin chi tiết: $detailUrl');

      final response = await http.get(
        Uri.parse(detailUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Response thông tin chi tiết: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isEmpty) {
          throw Exception('Dữ liệu nhân viên trống');
        }
        return data;
      } else {
        throw Exception('Lỗi khi lấy thông tin nhân viên: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi trong quá trình lấy thông tin: $e');
      throw Exception('Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to get gender text
  String _getGenderText(int? genderCode) {
    switch (genderCode) {
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

  // Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Không có thông tin';
    }
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  // Helper method to get status text
  String _getStatusText(int? statusCode) {
    switch (statusCode) {
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

  // Helper method to get icon for each field
  IconData _getIconForField(String fieldName) {
    switch (fieldName) {
      case 'Họ tên':
        return Icons.person;
      case 'Mã nhân viên':
        return Icons.badge;
      case 'Phòng ban':
        return Icons.work;
      case 'Chức vụ':
        return Icons.assignment_ind;
      case 'Giới tính':
        return Icons.transgender;
      case 'Ngày sinh':
        return Icons.cake;
      case 'Số điện thoại':
        return Icons.phone;
      case 'Địa chỉ':
        return Icons.location_on;
      case 'Ngày vào làm':
        return Icons.date_range;
      case 'Trạng thái':
        return Icons.work_outline;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin cá nhân'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _employeeInfo,
        builder: (context, snapshot) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text('Đã xảy ra lỗi:', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserIdAndFetchEmployeeInfo,
                    child: Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 50, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không tìm thấy dữ liệu nhân viên'),
                  SizedBox(height: 8),
                  Text(
                    'Vui lòng kiểm tra kết nối hoặc liên hệ quản trị viên',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    onPressed: _loadUserIdAndFetchEmployeeInfo,
                    label: Text('Tải lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }


          final employeeData = snapshot.data!;
          final department = employeeData['department'] ?? {};
          final position = employeeData['position'] ?? {};

          final userInfo = {
            'Họ tên': employeeData['fullName'] ?? 'Không có thông tin',
            'Mã nhân viên': employeeData['employeeId'] ?? 'Không có thông tin',
            'Phòng ban': department['name'] ?? 'Không có thông tin',
            'Chức vụ': position['name'] ?? 'Không có thông tin',
            'Giới tính': _getGenderText(employeeData['gender']),
            'Ngày sinh': _formatDate(employeeData['dateOfBirth']),
            'Số điện thoại': employeeData['phone'] ?? 'Không có thông tin',
            'Địa chỉ': employeeData['address'] ?? 'Không có thông tin',
            'Ngày vào làm': _formatDate(employeeData['hireDate']),
            'Trạng thái': _getStatusText(employeeData['status']),
          };

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: userInfo.length,
            itemBuilder: (context, index) {
              String key = userInfo.keys.elementAt(index);
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(_getIconForField(key), color: Colors.orange),
                  title: Text(key, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(userInfo[key]!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}