import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/ui/Hr/Setting/Navbar/Departmentpost.dart';
import 'package:sem4_fe/Service/Constants.dart';

// Thay URL này bằng link backend thực tế của bạn
const String apiUrl = Constants.departmentsUrl;

class DepartmentListScreen extends StatefulWidget {
  final String token;
  // bạn cần truyền token vào để xác thực

  const DepartmentListScreen({Key? key, required this.token}) : super(key: key);

  @override
  _DepartmentListScreenState createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  late Future<List<Department>> _futureDepartments;

  @override
  void initState() {
    super.initState();
    _futureDepartments = fetchDepartments();
  }

  Future<List<Department>> fetchDepartments() async {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['result'];
      return list.map((e) => Department.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi lấy dữ liệu phòng ban');
    }
  }

  void _confirmDelete(String departmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Xác nhận xóa',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa phòng ban này?',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.only(right: 12, bottom: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteDepartment(departmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteDepartment(String departmentId) async {
    final url = Uri.parse('${Constants.departmentsUrl}/$departmentId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    // print("ID cần xóa: $departmentId");
    // await deleteDepartment(departmentId);


    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        _futureDepartments = fetchDepartments(); // reload lại danh sách
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Xóa thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Xóa thất bại: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách phòng ban'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm phòng ban',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDepartmentScreen(token: widget.token),
                ),
              ).then((_) {
                // Reload lại danh sách sau khi thêm/sửa
                setState(() {
                  _futureDepartments = fetchDepartments();
                });
              });
            },
          ),
          const SizedBox(width: 12), // khoảng cách phải
        ],
      ),
      body: FutureBuilder<List<Department>>(
        future: _futureDepartments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('❌ ${snapshot.error}'));
          }

          final departments = snapshot.data!;
          if (departments.isEmpty) {
            return const Center(child: Text('Không có phòng ban nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: departments.length,
              itemBuilder: (context, index) {
                final dept = departments[index];
                final isActive = dept.status == 'Active';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.green[50] : Colors.red[50],
                        child: Icon(Icons.apartment_rounded, color: isActive ? Colors.green : Colors.red),
                      ),
                      title: Text(
                        dept.departmentName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: isActive ? Colors.green : Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                              style: TextStyle(
                                fontSize: 13,
                                color: isActive ? Colors.green : Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            tooltip: 'Sửa',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddDepartmentScreen(
                                    token: widget.token,
                                    department: dept,
                                  ),
                                ),
                              ).then((_) {
                                setState(() {
                                  _futureDepartments = fetchDepartments();
                                });
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            tooltip: 'Xóa',
                            onPressed: () => _confirmDelete(dept.departmentId),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        },
      ),
    );
  }
}

class Department {
  final String departmentId;
  final String departmentName;
  final String status;

  Department({
    required this.departmentId,
    required this.departmentName,
    required this.status,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['departmentId'] ?? '',
      departmentName: json['departmentName'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
