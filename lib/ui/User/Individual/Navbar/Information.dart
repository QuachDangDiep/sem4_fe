import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/UpdatePerson.dart';

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

      // Bước 1: Lấy employeeId từ userId
      final idRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (idRes.statusCode != 200) {
        throw Exception('Không lấy được employeeId');
      }

      final employeeId = idRes.body.trim();

      // Bước 2: Gọi API mới để lấy thông tin chi tiết nhân viên
      final infoRes = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (infoRes.statusCode != 200) {
        throw Exception('Không lấy được thông tin nhân viên');
      }

      final data = json.decode(infoRes.body);
      setState(() {
        _employeeInfo = Future.value(data);
      });
    } catch (e) {
      print('❌ Lỗi trong quá trình lấy thông tin: $e');
      setState(() {
        _employeeInfo = Future.error('Lỗi khi truy xuất thông tin nhân viên: ${e.toString()}');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _employeeInfo,
            builder: (context, snapshot) {
              return AppBar(
                backgroundColor: Colors.orange,
                automaticallyImplyLeading: true,
                centerTitle: true,
                title: const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                actions: [
                  if (snapshot.hasData)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdatePersonalInfoScreen(employeeData: snapshot.data!),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _employeeInfo,
          builder: (context, snapshot) {
            if (_isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Không có dữ liệu nhân viên'));
            }

            final employeeData = snapshot.data!;
            final department = employeeData['department'] ?? {};
            final position = employeeData['position'] ?? {};

            final personalInfo = {
              'Họ tên': employeeData['fullName'] ?? 'Không có thông tin',
              'Giới tính': employeeData['gender'] ?? 'Không có thông tin',
              'Ngày sinh': _formatDate(employeeData['dateOfBirth']),
              'Số điện thoại': employeeData['phone'] ?? 'Không có thông tin',
              'Địa chỉ': employeeData['address'] ?? 'Không có thông tin',
            };

            final workInfo = {
              'Mã nhân viên': employeeData['employeeId'] ?? 'Không có thông tin',
              'Phòng ban': employeeData['departmentName'] ?? 'Không có thông tin',
              'Chức vụ': employeeData['positionName'] ?? 'Không có thông tin',
              'Ngày vào làm': _formatDate(employeeData['hireDate']),
              'Ngày tạo hồ sơ': _formatDate(employeeData['createdAt']),
              'Ngày cập nhật': _formatDate(employeeData['updatedAt']),
              'Trạng thái': employeeData['status'] ?? 'Không có thông tin',
            };

            return Column(
              children: [
                SizedBox(height: 16),
                // Avatar và thông tin cơ bản
                Center(
                  child: (employeeData['img'] ?? '').toString().isNotEmpty
                      ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(employeeData['img']),
                    backgroundColor: Colors.grey[200],
                  )
                      : CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                    backgroundColor: Colors.orange,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  employeeData['fullName'] ?? '',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Mã NV: ${employeeData['employeeId'] ?? 'Không có'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),

                // TabBar ngay bên dưới avatar
                TabBar(
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.orange,
                  tabs: [
                    Tab(text: 'Cá nhân'),
                    Tab(text: 'Làm việc'),
                  ],
                ),

                // Nội dung tab
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: _buildInfoList(personalInfo),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: _buildInfoList(workInfo),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }



  // Widget chung để hiển thị list thông tin
  Widget _buildInfoList(Map<String, dynamic> infoMap) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: infoMap.length,
      separatorBuilder: (context, index) => SizedBox(height: 6),
      itemBuilder: (context, index) {
        String key = infoMap.keys.elementAt(index);
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Icon(_getIconForField(key), color: Colors.orange),
            ),
            title: Text(key, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(infoMap[key]?.toString() ?? ''),
          ),
        );
      },
    );
  }
}