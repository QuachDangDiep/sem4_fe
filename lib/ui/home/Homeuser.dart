import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/ui/QR/Checkin.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String token;

  const HomeScreen({
    Key? key,
    required this.username,
    required this.token,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['result'] != null) {
          List users = responseData['result'];

          final user = users.firstWhere(
                (u) => u['username'] == widget.username,
            orElse: () => null,
          );

          setState(() {
            userData = user;
            isLoading = false;
          });
        } else {
          throw Exception('Không có danh sách người dùng trong kết quả');
        }
      } else {
        throw Exception('Không thể lấy thông tin người dùng');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData == null
            ? const Center(child: Text("Không tìm thấy người dùng"))
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage:
                        AssetImage('assets/avatar.png'),
                        radius: 24,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Xin chào,",
                              style: TextStyle(fontSize: 14)),
                          Text(
                            userData!['username'],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "${DateTime.now().day.toString().padLeft(2, '0')}/"
                            "${DateTime.now().month.toString().padLeft(2, '0')}/"
                            "${DateTime.now().year}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: "Tìm kiếm",
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info Card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border:
                  Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    infoRow(Icons.location_on_outlined, "Cơ sở:",
                        "Ton That Thuyet"),
                    infoRow(Icons.account_tree_outlined, "Phòng ban:",
                        "Data Department", boldValue: true),
                    infoRow(Icons.badge_outlined, "MNV:", "DD005",
                        valueColor: Colors.deepPurple),
                    infoRow(Icons.work_outline, "Nghiệp vụ:", "Dev",
                        valueColor: Colors.deepPurple),
                    const Divider(),
                    GestureDetector(
                      onTap: () {
                        // đi tới trang chấm công
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.access_time,
                              size: 18, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text("Chưa chấm công!",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500)),
                          Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Check In Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckInPage(
                              username: widget.username,
                              token: widget.token,
                            ),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text("Check In"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Check Out Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // check out action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text("Check Out"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang Chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Cá Nhân",
          ),
        ],
      ),
    );
  }

  // Helper widget
  Widget infoRow(IconData icon, String label, String value,
      {bool boldValue = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
