import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';

class AttendanceManagementScreen extends StatefulWidget {
  final String token;

  const AttendanceManagementScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  List<dynamic> attendanceList = [];
  List<dynamic> employeeList = [];
  bool isLoading = true;
  String? selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    fetchEmployeeList();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(Constants.activeQrAttendanceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          attendanceList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance records');
      }
    } catch (e) {
      print('Lỗi khi tải chấm công: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> getUserRoleId() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.rolesUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final roles = decoded['result'] ?? [];

        print('Danh sách vai trò từ API rolesUrl: $roles');

        final userRoles = roles.where((r) => r['roleName']?.toString().toLowerCase() == 'user').toList();

        if (userRoles.isNotEmpty) {
          final roleId = userRoles.first['roleId']?.toString();
          print('roleId của user: $roleId');
          return roleId;
        } else {
          print('Không tìm thấy vai trò "user" trong danh sách vai trò');
        }
      } else {
        print('Lỗi lấy danh sách vai trò: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi getUserRoleId: $e');
    }
    return null;
  }

  Future<List<dynamic>> fetchUsers({String? roleId, String? status}) async {
    try {
      final queryParameters = status != null ? {'status': status} : <String, String>{};
      final uri = Uri.parse(Constants.homeUrl).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final usersRaw = jsonDecode(response.body)['result'] ?? [];
        List<dynamic> users = [];

        for (final json in usersRaw) {
          print('UserId: ${json['userId']} - Role: ${json['role']}');

          // Kiểm tra trường role trực tiếp
          bool hasRole = json['role']?.toString() == roleId;

          if (roleId != null && !hasRole) {
            continue;
          }

          users.add(json);
        }

        print('Số lượng người dùng có vai trò user: ${users.length}');
        return users;
      } else {
        print('Lỗi lấy danh sách users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi fetchUsers: $e');
    }

    return [];
  }

  Future<void> fetchEmployeeList() async {
    try {
      setState(() {
        isLoading = true;
      });

      final roleId = await getUserRoleId();
      if (roleId == null) {
        print('Không tìm thấy roleId cho vai trò user');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final users = await fetchUsers(roleId: roleId);
      List<dynamic> filteredEmployees = [];

      for (final user in users) {
        final employeeIdResponse = await http.get(
          Uri.parse(Constants.employeeIdByUserIdUrl(user['userId'])),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (employeeIdResponse.statusCode != 200 || employeeIdResponse.body.trim().isEmpty) {
          print('Không lấy được employeeId cho userId: ${user['userId']}');
          continue;
        }

        final employeeId = employeeIdResponse.body.trim();

        final detailResponse = await http.get(
          Uri.parse(Constants.employeeDetailUrl(employeeId)),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (detailResponse.statusCode == 200) {
          final employee = jsonDecode(detailResponse.body);
          filteredEmployees.add(employee);
        } else {
          print('Lỗi lấy chi tiết nhân viên $employeeId: ${detailResponse.statusCode}');
        }
      }

      setState(() {
        employeeList = filteredEmployees;
        isLoading = false;
      });

      print('Tổng số nhân viên có role user: ${employeeList.length}');
    } catch (e) {
      print('Lỗi API nhân viên với roleId: $e');
      setState(() {
        isLoading = false;
      });
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

  List<dynamic> getFilteredAttendance() {
    if (selectedEmployeeId == null || selectedEmployeeId!.isEmpty) {
      return attendanceList;
    }

    return attendanceList.where((item) => item['employee']?['employeeId'] == selectedEmployeeId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = getFilteredAttendance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chấm công'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Dropdown chọn nhân viên
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              value: selectedEmployeeId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Chọn nhân viên',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: employeeList.map<DropdownMenuItem<String>>((employee) {
                final empId = employee['employeeId']?.toString();
                print('Thêm nhân viên vào Dropdown: ${employee['fullName']} - $empId');
                return DropdownMenuItem<String>(
                  value: empId,
                  child: Text(employee['fullName'] ?? 'Không rõ tên'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEmployeeId = value;
                });
              },
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(child: Text('Không có dữ liệu chấm công'))
                : ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final employeeMap = item['employee'];
                final empId = employeeMap?['employeeId'] ?? 'N/A';
                final empName = employeeMap?['fullName'] ?? 'Không rõ tên';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(20),
                    shadowColor: Colors.black12,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.orange,
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      empName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Mã NV: $empId',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 12),

                          buildInfoRow(Icons.calendar_today, 'Ngày chấm công:',
                              formatDate(item['attendanceDate'] ?? ''), iconColor: Colors.indigo),

                          const SizedBox(height: 8),

                          buildInfoRow(Icons.fingerprint, 'Phương thức:',
                              item['attendanceMethod'] ?? 'N/A', iconColor: Colors.deepPurple),

                          const SizedBox(height: 8),

                          buildInfoRow(Icons.check_circle, 'Trạng thái:', item['status'] ?? 'N/A',
                              iconColor: item['status']?.toLowerCase() == 'active'
                                  ? Colors.red
                                  : Colors.green),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
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
}