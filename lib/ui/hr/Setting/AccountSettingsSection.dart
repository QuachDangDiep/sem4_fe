import 'package:flutter/material.dart';

class AccountSettingsSection extends StatefulWidget {
  @override
  _AccountSettingsSectionState createState() =>
      _AccountSettingsSectionState();
}

class _AccountSettingsSectionState extends State<AccountSettingsSection> {
  bool isExpanded = true;
  bool isTwoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          isExpanded = expanded;
        });
      },
      leading: Icon(Icons.person, color: Colors.deepPurple),
      title: Text(
        'Cài đặt tài khoản',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300), // 👉 Giới hạn chiều cao
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Thông tin cá nhân'),
                    subtitle: Text('Cập nhật thông tin cá nhân của bạn'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Chuyển đến trang chỉnh sửa thông tin cá nhân
                    },
                  ),
                  ListTile(
                    title: Text('Đổi mật khẩu'),
                    subtitle: Text('Thay đổi mật khẩu đăng nhập của bạn'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Chuyển đến trang đổi mật khẩu
                    },
                  ),
                  SwitchListTile(
                    title: Text('Xác thực 2 lớp'),
                    subtitle: Text('Bảo mật tài khoản với xác thực 2 lớp'),
                    value: isTwoFactorEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        isTwoFactorEnabled = value;
                      });
                      // TODO: Thêm xử lý lưu trạng thái xác thực 2 lớp
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Xử lý đăng xuất
                      },
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Đăng xuất',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
