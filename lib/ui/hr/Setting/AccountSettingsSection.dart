import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/ChangePasswordPage.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Information.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsSection extends StatefulWidget {
  final String username;
  final String token;

  const AccountSettingsSection({
    super.key,
    required this.username,
    required this.token,
  });

  @override
  State<AccountSettingsSection> createState() => _AccountSettingsSectionState();
}

class _AccountSettingsSectionState extends State<AccountSettingsSection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 3,
        title: const Text(
          "Tài khoản của tôi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.deepPurple),
                title: const Text(
                  "Thông tin cá nhân",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInfoScreen(token: widget.token),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.teal),
                title: const Text(
                  "Đổi mật khẩu",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordPage(
                        token: widget.token, // ✅ Chỉ truyền token
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
