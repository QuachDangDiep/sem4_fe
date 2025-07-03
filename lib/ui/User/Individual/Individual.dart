import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Information.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Timesheet.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/WorkHistory.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/ChangePasswordPage.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/histotyqr.dart';
import 'package:sem4_fe/ui/login/Login.dart';

class PersonalPage extends StatelessWidget {
  const PersonalPage({Key? key}) : super(key: key);

  Widget buildMenuItem(String title, IconData icon, VoidCallback onTap,
      {Color? backgroundColor}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: backgroundColor ?? Colors.blue,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Xác nhận đăng xuất'),
                    ],
                  ),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
                  actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: ListView(
        children: [
          buildMenuItem('Thông tin cá nhân', Icons.person, () async {
            try {
              // Lấy token từ SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng đăng nhập lại')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalInfoScreen(token: token),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi lấy thông tin đăng nhập: ${e.toString()}')),
              );
            }
          }, backgroundColor: Colors.orange),
          buildMenuItem('Lịch sử chấm công', Icons.history, () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng đăng nhập lại')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceHistoryScreen(token: token), // Hoặc tên class đúng trong historyqr.dart
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi chuyển trang: ${e.toString()}')),
              );
            }
          }, backgroundColor: Colors.blue),

          buildMenuItem('Bảng công', Icons.grid_on, () async {
            try {
              // Lấy token từ SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token'); // 'auth_token' là key bạn dùng để lưu token

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng đăng nhập lại')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceSummaryScreen(token: token),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi lấy thông tin đăng nhập: ${e.toString()}')),
              );
            }
          }, backgroundColor: Colors.cyan),
          buildMenuItem('Bảng phép, thâm niên', Icons.event_note, () {},
              backgroundColor: Colors.lightBlue),
          buildMenuItem('Lịch sửa làm việc', Icons.description, () async {
            try {
              // Lấy token từ SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token'); // 'auth_token' là key bạn dùng để lưu token

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng đăng nhập lại')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkHistoryScreen(token: token),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi lấy thông tin đăng nhập: ${e.toString()}')),
              );
            }
          },
              backgroundColor: Colors.amber),
          buildMenuItem('Đổi mật khẩu', Icons.vpn_key, () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập lại')),
                );
                return;
              }

              // Giải mã token để lấy userId
              final decodedToken = JwtDecoder.decode(token);
              final userId = decodedToken['userId'] ?? decodedToken['sub'];

              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không tìm thấy userId trong token')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordPage(userId: userId.toString(), token: '',),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi lấy thông tin đăng nhập: ${e.toString()}')),
              );
            }
          },
              backgroundColor: Colors.teal),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

