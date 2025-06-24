import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Navbar/LeaveRegistration.dart';

class ProposalPage extends StatelessWidget {
  const ProposalPage({Key? key}) : super(key: key);

  Widget buildProposalItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(useMaterial3: false), // Tắt Material 3 cho riêng trang này
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Đề xuất',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: kToolbarHeight + 24),
          children: [
            buildProposalItem('Đăng ký nghỉ', Icons.airline_seat_individual_suite, Colors.orange, () async {
              try {
                // Lấy token từ SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final employeeId = prefs.getString('employee_id');
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
                    builder: (context) => LeaveRegistrationPage(token: token, employeeId: employeeId ?? ''),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi lấy thông tin đăng nhập: ${e.toString()}')),
                );
              }
            }
            ),
            buildProposalItem('Đi muộn về sớm', Icons.access_time, Colors.green, () {}),
            buildProposalItem('Làm thêm giờ', Icons.calculate, Colors.blue, () {}),
            buildProposalItem('Làm việc ngoài công ty, công tác', Icons.group_work, Colors.purple, () {}),
            buildProposalItem('Giải trình chấm công', Icons.note_alt, Colors.deepOrange, () {}),
            buildProposalItem('Đổi ca', Icons.sync_alt, Colors.green, () {}),
            buildProposalItem('Đăng ký ra ngoài', Icons.double_arrow, Colors.indigo, () {}),
          ],
        ),
      ),
    );
  }
}