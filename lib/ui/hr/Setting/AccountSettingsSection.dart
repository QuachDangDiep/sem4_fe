import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/login/Login.dart';

class AccountSettingsSection extends StatefulWidget {
  @override
  _AccountSettingsSectionState createState() => _AccountSettingsSectionState();
}

class _AccountSettingsSectionState extends State<AccountSettingsSection> {
  bool isTwoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 280, // giới hạn chiều cao tổng thể hợp lý hơn
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true, // giảm padding dọc
              title: Text('Thông tin cá nhân'),
              subtitle: Text('Cập nhật thông tin cá nhân của bạn'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Chuyển đến trang chỉnh sửa thông tin cá nhân
              },
            ),
            ListTile(
              dense: true,
              title: Text('Đổi mật khẩu'),
              subtitle: Text('Thay đổi mật khẩu đăng nhập của bạn'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Chuyển đến trang đổi mật khẩu
              },
            ),
            SwitchListTile(
              dense: true,
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
            Divider(height: 1, color: Colors.grey.shade300),
            ListTile(
              dense: true,
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
                // TODO: Xử lý đăng xuất
              },
            ),
          ],
        ),
      ),
    );
  }
}
