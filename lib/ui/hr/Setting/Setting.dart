import 'package:flutter/material.dart';
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
  @override
  State<HrSettingsPage> createState() => _HrSettingsPageState();
}

class _HrSettingsPageState extends State<HrSettingsPage> {
  final List<SettingItem> settingItems = [
    SettingItem(Icons.business, 'Thông tin công ty'),
    SettingItem(Icons.person, 'Cài đặt tài khoản'),
    SettingItem(Icons.settings, 'Cài đặt hệ thống'),
    SettingItem(Icons.lock, 'Quản lý quyền truy cập'),
    SettingItem(Icons.notifications, 'Thông báo'),
    SettingItem(Icons.info, 'Thông tin ứng dụng'),
  ];

  String expandedTitle = ''; // Lưu mục đang mở rộng

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Cài đặt',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/user_avatar.jpg'),
            ),
          )
        ],
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
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Icon(item.icon, color: Colors.deepPurple),
                  ),
                  title: Text(item.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  trailing: item.title == 'Thông tin ứng dụng'
                      ? null
                      : Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                  ),
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
                                child: const Text('Đóng'),
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
          Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          height: 400, // hoặc chiều cao phù hợp với nội dung của CompanyInfoSection
          child: CompanyInfoSection(),
                ),

              // Tương tự thêm các phần mở rộng khác
            ],
          );
        },
      ),
    );
  }
}
