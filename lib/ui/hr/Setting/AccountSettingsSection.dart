import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/ChangePasswordPage.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Information.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart'; // Đảm bảo bạn có file này để lấy URL API

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
        elevation: 2,
        title: const Text("Tài khoản"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.deepOrange),
                title: const Text(
                  "Thông tin cá nhân",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () async {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('auth_token');

                    if (token == null || token.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
                      );
                      return;
                    }

                    final decoded = JwtDecoder.decode(token);
                    final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
                    if (userId == null) {
                      throw Exception('Không tìm thấy userId trong token');
                    }

                    final idRes = await http.get(
                      Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
                      headers: {'Authorization': 'Bearer $token'},
                    );

                    print('🔍 Calling: ${Constants.employeeIdByUserIdUrl(userId)}');
                    print('🔐 Token: $token');
                    print('📡 Response Code: ${idRes.statusCode}');
                    print('📄 Response Body: ${idRes.body}');

                    if (idRes.statusCode != 200) {
                      throw Exception('Không thể lấy employeeId');
                    }

                    final employeeId = idRes.body.trim();

                    final infoRes = await http.get(
                      Uri.parse(Constants.employeeDetailUrl(employeeId)),
                      headers: {'Authorization': 'Bearer $token'},
                    );

                    if (infoRes.statusCode != 200) {
                      throw Exception('Không thể lấy thông tin nhân viên');
                    }

                    final employeeData = json.decode(infoRes.body);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalInfoScreen(
                          token: token,
                          employeeId: employeeId,
                          employeeData: employeeData,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                        token: widget.token,
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
