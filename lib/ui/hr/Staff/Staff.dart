import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/ui/hr/home/HomeHr.dart'; // Điều chỉnh đường dẫn nếu cần

// Model cho UserResponse
class UserResponse {
  final String id;
  final String username;
  final String email;
  final String role;
  final String status;
  final String? shift;
  final String? image;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    this.shift,
    this.image,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['userId']?.toString() ?? 'Unknown',
      username: json['username'] ?? 'Không xác định',
      email: json['email'] ?? 'Không có email',
      role: json['role'] ?? 'Không có vai trò',
      status: json['status'] == 'Active' ? 'Đang làm việc' : json['status'] ?? 'Không xác định',
      shift: json['shift'] ?? 'Không có ca',
      image: json['image'] ?? 'assets/avatar.jpg',
    );
  }
}

class StaffScreen extends StatefulWidget {
  final String username;
  final String token;

  const StaffScreen({super.key, required this.token, required this.username});

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late Future<List<UserResponse>> _usersFuture;
  // UUID của vai trò "user" – thay bằng UUID thực tế từ backend
  static const String userRoleId = 'a9e42b35-4059-11f0-8c6f-04bf1b09e9e6';

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

  Future<List<UserResponse>> fetchUsers({String? status}) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/users${status != null ? '?status=$status' : ''}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> users = data['result'] ?? [];
        // Lọc chỉ người dùng có role là "user"
        return users
            .map((json) => UserResponse.fromJson(json))
            .where((user) => user.role == userRoleId)
            .toList();
      } else {
        throw Exception('Không thể tải danh sách người dùng: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Lỗi khi lấy danh sách người dùng: $e');
    }
  }

  void refreshUsers() {
    setState(() {
      _usersFuture = fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nhân sự'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    '3',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.jpg'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tìm kiếm + Lọc
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhân viên...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      // Thêm logic tìm kiếm nếu cần
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _usersFuture = fetchUsers(status: 'Active');
                    });
                  },
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Lọc'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                )
              ],
            ),
          ),
          // Danh sách nhân viên
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
                        Text('Lỗi: ${snapshot.error}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: refreshUsers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không tìm thấy người dùng với vai trò user'));
                }

                final users = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return StaffCard(
                      name: user.username,
                      id: user.id,
                      role: user.role,
                      status: user.status,
                      shift: user.shift ?? 'Không có ca',
                      image: user.image ?? 'assets/avatar.jpg',
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
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeHRPage(
                  username: widget.username,
                  token: widget.token,
                ),
              ),
            );
          }
          // Xử lý các tab khác nếu cần
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Nhân viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Chấm công',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final String name;
  final String id;
  final String role;
  final String status;
  final String shift;
  final String image;

  const StaffCard({
    super.key,
    required this.name,
    required this.id,
    required this.role,
    required this.status,
    required this.shift,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == 'Đang làm việc'
        ? Colors.green.shade100
        : Colors.orange.shade100;
    Color statusTextColor = status == 'Đang làm việc'
        ? Colors.green.shade800
        : Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: image.startsWith('http')
              ? NetworkImage(image)
              : AssetImage(image) as ImageProvider,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã NV: $id'),
            Text('Email: $role'), // Hiển thị email thay vì role UUID
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusTextColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shift,
                style: TextStyle(
                  color: Colors.deepPurple.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}