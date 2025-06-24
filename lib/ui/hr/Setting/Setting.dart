import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/hr/home/HomeHr.dart';
import 'package:sem4_fe/ui/hr/Staff/Staff.dart';
import 'package:sem4_fe/ui/hr/Setting/CompanyInfoSection.dart';
import 'package:sem4_fe/ui/hr/Setting/AccountSettingsSection.dart';
import 'package:sem4_fe/ui/hr/Setting/SystemSettingsSection.dart';
import 'package:sem4_fe/ui/hr/Setting/AccessControlSection.dart';
import 'package:sem4_fe/ui/hr/Setting/NotificationSettingsSection.dart';

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
  int _selectedIndex = 4;

  final List<SettingItem> settingItems = [
    SettingItem(Icons.business, 'Thông tin công ty'),
    SettingItem(Icons.person, 'Cài đặt tài khoản'),
    SettingItem(Icons.settings, 'Cài đặt hệ thống'),
    SettingItem(Icons.lock, 'Quản lý quyền truy cập'),
    SettingItem(Icons.notifications, 'Thông báo'),
    SettingItem(Icons.info, 'Thông tin ứng dụng'),
  ];

  String expandedTitle = '';

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffScreen(username: widget.username, token: widget.token)),
        );
        break;
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chức năng ${index == 2 ? "Chấm công" : "Báo cáo"} đang được phát triển')),
        );
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: colors[1],
        elevation: 2,
        title: const Text('Cài đặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: colors[3]),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: settingItems.length,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final item = settingItems[index];
          final isExpanded = item.title == expandedTitle;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors[0],
                    child: Icon(item.icon, color: colors[3]),
                  ),
                  title: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  trailing: item.title == 'Thông tin ứng dụng'
                      ? null
                      : Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: colors[3]),
                  onTap: () {
                    setState(() {
                      if (item.title == 'Thông tin ứng dụng') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
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
                      } else {
                        expandedTitle = isExpanded ? '' : item.title;
                      }
                    });
                  },
                ),
              ),
              if (item.title == 'Thông tin công ty' && isExpanded)
                sectionWrapper(CompanyInfoSection()),
              if (item.title == 'Cài đặt tài khoản' && isExpanded)
                sectionWrapper(AccountSettingsSection()),
              if (item.title == 'Cài đặt hệ thống' && isExpanded)
                sectionWrapper(SystemSettingsSection()),
              if (item.title == 'Quản lý quyền truy cập' && isExpanded)
                sectionWrapper(AccessControlSection()),
              if (item.title == 'Thông báo' && isExpanded)
                sectionWrapper(NotificationSettingsSection()),
            ],
          );
        },
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
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), label: 'Nhân viên'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint_outlined), label: 'Chấm công'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }

  Widget sectionWrapper(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}