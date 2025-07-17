import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/login/Login.dart';
import 'package:sem4_fe/ui/Hr/Setting/CompanyInfoSection.dart';
import 'package:sem4_fe/ui/Hr/Setting/AccountSettingsSection.dart';
import 'package:sem4_fe/ui/Hr/Setting/Navbar/HRWorkScheduleScreen.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Attendance.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/histotyqr.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/LeaveRegistration.dart';
import 'package:sem4_fe/ui/Hr/Setting/Navbar/AttendanceManagementScreen.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/AttendanceAppealPage.dart';

class SettingItem {
  final IconData icon;
  final String title;

  SettingItem(this.icon, this.title);
}

class HrSettingsPage extends StatefulWidget {
  final String username, token;

  const HrSettingsPage({super.key, required this.username, required this.token});

  @override
  State<HrSettingsPage> createState() => _HrSettingsPageState();
}

class _HrSettingsPageState extends State<HrSettingsPage> {
  final colors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFFFA726),
    const Color(0xFFFB8C00),
    const Color(0xFFEF6C00),
  ];

  final List<SettingItem> settingItems = [
    SettingItem(Icons.business, 'Thông tin công ty'),
    SettingItem(Icons.person, 'Cài đặt tài khoản'),
    SettingItem(Icons.schedule, 'Quản lý chấm công'),
    SettingItem(Icons.apartment, 'Đơn xin nghỉ'),
    SettingItem(Icons.table_chart, 'Bảng công'), // ✅ đổi icon phù hợp
    SettingItem(Icons.history, 'Lịch sử chấm công'), // ✅ đổi icon phù hợp
    SettingItem(Icons.edit_note, 'Giải trình chấm công'),
    SettingItem(Icons.info_outline, 'Thông tin ứng dụng'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text(
          'Quản lý',
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
      body: ListView.builder(
        itemCount: settingItems.length,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final item = settingItems[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colors[0],
                child: Icon(item.icon, color: colors[3]),
              ),
              title: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: item.title == 'Thông tin ứng dụng' ? null : Icon(Icons.arrow_forward_ios, size: 16, color: colors[3]),
              onTap: () {
                if (item.title == 'Thông tin công ty') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyInfoSection(username: widget.username, token: widget.token)));
                } else if (item.title == 'Cài đặt tài khoản') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AccountSettingsSection(username: widget.username, token: widget.token)));
                } else if (item.title == 'Danh sách đăng ký ca làm') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HRWorkScheduleScreen(token: widget.token)));
                } else if (item.title == 'Quản lý chấm công') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AttendanceManagementScreen(token: widget.token),
                  ));
                } else if (item.title == 'Giải trình chấm công') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      AttendanceAppealPage(token: widget.token)));
                } else if (item.title.toLowerCase() == 'bảng công') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceSummaryScreen(token: widget.token)));
                } else if (item.title.toLowerCase() == 'lịch sử chấm công') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceHistoryScreen(token: widget.token)));
                } else if (item.title == 'Đơn xin nghỉ') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveRegistrationPage(token: widget.token)));
                } else if (item.title == 'Thông tin ứng dụng') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Thông tin ứng dụng'),
                      content: const Text('Phiên bản 1.0.0\nGive-AID'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Đóng', style: TextStyle(color: colors[3])),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
