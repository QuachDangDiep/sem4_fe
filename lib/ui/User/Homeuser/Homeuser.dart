import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/ui/User//Individual/Individual.dart';
import 'package:sem4_fe/ui/User//Notification/Notification.dart';
import 'package:sem4_fe/ui/User//Propose/Propose.dart';
import 'package:sem4_fe/ui/User//QR/Qrscanner.dart';
import 'package:sem4_fe/Service/Constants.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String token;

  const HomeScreen({
    Key? key,
    required this.username,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.homeUrl),
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
            userData = user != null ? Map<String, dynamic>.from(user) : null;
            isLoading = false;
          });
        } else {
          throw Exception('Không có dữ liệu người dùng trong kết quả');
        }
      } else {
        throw Exception('Không thể lấy thông tin người dùng (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải người dùng: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void showCheckInOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn phương thức chấm công',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCheckInOption(
                      icon: Icons.wifi,
                      title: 'Wifi',
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: xử lý chấm công Wifi
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCheckInOption(
                      icon: Icons.gps_fixed,
                      title: 'GPS',
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: xử lý chấm công GPS
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCheckInOption(
                      icon: Icons.qr_code,
                      title: 'QrCode',
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToQRScanner();
                      },
                    ),
                  ],
                ),
              ),
              // Nút đóng ở góc trên bên phải
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          username: widget.username,
          token: widget.token,
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userData == null) {
      return const Center(child: Text("Không tìm thấy người dùng"));
    }

    return Container(
    color: Colors.white,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar và thông tin người dùng
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (userData!['avatarUrl'] != null &&
                    userData!['avatarUrl'].toString().isNotEmpty)
                    ? NetworkImage(userData!['avatarUrl'])
                    : const AssetImage('assets/avatar.jpg')
                as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Xin chào,",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData!['fullName'] ?? widget.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData!['position'] ?? 'Cộng tác viên kinh doanh',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ca làm việc
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Ca làm việc",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vào ca", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 4),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ra ca", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 4),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chấm công chính
          GestureDetector(
            onTap: showCheckInOptions,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFD49A2F),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    "Chấm công",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2 phần chấm công khác nằm ngang
          Row(
            children: [
              Expanded(
                child: _buildQRAction(
                  icon: Icons.access_time_filled,
                  text: "Chấm công làm thêm giờ",
                  color: const Color(0xFFF29F05),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQRAction(
                  icon: Icons.shield_moon,
                  text: "Chấm công trực ca / trực gác",
                  color: const Color(0xFF007B83),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trạng thái
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "Hôm nay bạn chưa chấm công",
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }

  Widget _buildQRAction({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _navigateToQRScanner,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationPage() {
    return const Center(
      child: Text(
        "Thông báo",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSuggestionPage() {
    return const Center(
      child: Text(
        "Đề xuất",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfilePage() {
    return const Center(
      child: Text(
        "Tài khoản",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      ProposalPage(),
      NotificationPage(),
      PersonalPage(),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white, // hoặc Colors.grey[100] để tạo cảm giác dịu
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFD49A2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Đề xuất'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
