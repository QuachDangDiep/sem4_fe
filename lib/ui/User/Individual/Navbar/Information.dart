// PersonalInfoScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/UpdatePerson.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String token;
  final String employeeId;
  final Map<String, dynamic> employeeData;

  const PersonalInfoScreen({
    Key? key,
    required this.token,
    required this.employeeId,
    required this.employeeData,
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
      data['token'] = token;

      setState(() {
        _employeeInfo = Future.value(data);
      });
    } catch (e) {
      print('❌ Lỗi: $e');
      setState(() {
        _employeeInfo = Future.error('Lỗi khi lấy dữ liệu: ${e.toString()}');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Không có thông tin';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  IconData _getIconForField(String fieldName) {
    switch (fieldName) {
      case 'Họ tên': return Icons.person;
      case 'Mã nhân viên': return Icons.badge;
      case 'Phòng ban': return Icons.work;
      case 'Chức vụ': return Icons.assignment_ind;
      case 'Giới tính': return Icons.transgender;
      case 'Ngày sinh': return Icons.cake;
      case 'Số điện thoại': return Icons.phone;
      case 'Địa chỉ': return Icons.location_on;
      case 'Ngày vào làm': return Icons.date_range;
      case 'Trạng thái': return Icons.work_outline;
      default: return Icons.info;
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
                title: const Text('Thông tin cá nhân', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                actions: [
                  if (snapshot.hasData)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateEmployeeScreen(
                              token: widget.token,
                              employeeId: widget.employeeId,
                              employeeData: widget.employeeData,
                            ),
                          ),
                        );
                        if (result == true) _fetchEmployeeInfo();
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
            if (_isLoading) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Không có dữ liệu nhân viên'));

            final employeeData = snapshot.data!;
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

            final imgData = employeeData['img'] ?? '';
            ImageProvider avatarProvider;
            try {
              avatarProvider = MemoryImage(base64Decode(imgData));
            } catch (e) {
              avatarProvider = const AssetImage('assets/images/avatar_placeholder.png');
            }

            return Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  employeeData['fullName'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Mã NV: ${employeeData['employeeId'] ?? 'Không có'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TabBar(
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.orange,
                  tabs: const [
                    Tab(text: 'Cá nhân'),
                    Tab(text: 'Làm việc'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildInfoList(personalInfo),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
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

  Widget _buildInfoList(Map<String, dynamic> infoMap) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: infoMap.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final key = infoMap.keys.elementAt(index);
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Icon(_getIconForField(key), color: Colors.orange),
            ),
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(infoMap[key]?.toString() ?? ''),
          ),
        );
      },
    );
  }
}
