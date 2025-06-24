import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/ui/hr/home/HomeHr.dart';
import 'package:sem4_fe/ui/hr/Setting/Setting.dart';

class UserResponse {
  final String id, username, email, role, status;
  final String? shift, image;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    this.shift,
    this.image,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['userId']?.toString() ?? 'Unknown',
    username: json['username'] ?? 'Không xác định',
    email: json['email'] ?? 'Không có email',
    role: json['role']?.toString() ?? 'Không xác định',
    status: json['status'] == 'Active' ? 'Đang làm việc' : (json['status']?.toString() ?? 'Không xác định'),
    shift: json['shift']?.toString(),
    image: json['image']?.toString() ?? 'assets/avatar.jpg',
  );
}

class StaffScreen extends StatefulWidget {
  final String username, token;

  const StaffScreen({Key? key, required this.token, required this.username}) : super(key: key);

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late Future<List<UserResponse>> _usersFuture;
  final colors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFFFA726),
    const Color(0xFFFB8C00),
    const Color(0xFFEF6C00),
  ];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

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
      final queryParameters = status != null ? {'status': status} : <String, String>{};
      final uri = Uri.parse('http://10.0.2.2:8080/api/users').replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      print('Users API Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final users = (jsonDecode(response.body)['result'] ?? [])
            .map<UserResponse>((json) {
          print('Processing user: $json');
          return UserResponse.fromJson(json);
        })
            .where((user) => user.role == roleId)
            .toList();
        print('Returning ${users.length} users');
        return users;
      }
      throw Exception('Không thể tải danh sách người dùng: ${response.statusCode}');
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách người dùng: $e');
    }
  }

  void refreshUsers() {
    setState(() {
      _usersFuture = fetchUsers();
      print('Refreshing users with role User...');
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeHRPage(username: widget.username, token: widget.token)),
        );
        break;
      case 1:
        break;
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chức năng ${index == 2 ? "Chấm công" : "Báo cáo"} đang được phát triển')),
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
        title: const Text('Quản lý Nhân sự', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: colors[3])),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhân viên...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      // Implement search logic
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _usersFuture = fetchUsers(status: 'Active');
                    print('Filtering active users with role User...');
                  }),
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Lọc'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors[3],
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: colors[3])),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserResponse>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi: ${snapshot.error}', style: TextStyle(color: colors[2])),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: refreshUsers,
                          style: ElevatedButton.styleFrom(backgroundColor: colors[3], foregroundColor: Colors.white),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Không tìm thấy người dùng', style: TextStyle(color: colors[2])));
                }
                final users = snapshot.data!;
                print('Rendering ${users.length} users');
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return StaffCard(
                      name: user.username,
                      id: user.id,
                      status: user.status,
                      shift: user.shift ?? 'Không có ca',
                      image: user.image ?? 'assets/avatar.jpg',
                      colors: colors,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshUsers,
        backgroundColor: colors[3],
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: colors[3],
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Nhân viên'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint_outlined), label: 'Chấm công'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final String name, id, status, shift, image;
  final List<Color> colors;

  const StaffCard({
    Key? key,
    required this.name,
    required this.id,
    required this.status,
    required this.shift,
    required this.image,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Đang làm việc' ? Colors.green.shade100 : Colors.orange.shade100;
    final statusTextColor = status == 'Đang làm việc' ? Colors.green.shade800 : Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: image.startsWith('http') ? NetworkImage(image) : const AssetImage('assets/avatar.jpg'),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã NV: $id'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
              child: Text(status, style: TextStyle(color: statusTextColor, fontSize: 12)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(20)),
              child: Text(shift, style: TextStyle(color: colors[3], fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}