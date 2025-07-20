import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/Hr/HRNotification/Navbar/NotificationToRoles.dart';
import 'package:sem4_fe/ui/Hr/HRNotification/Navbar/NotificationToUser.dart';
class HRNotificationScreen extends StatefulWidget {
  final String token;

  const HRNotificationScreen({
    super.key,
    required this.token,
  });

  @override
  State<HRNotificationScreen> createState() => _HRNotificationScreenState();
}

class _HRNotificationScreenState extends State<HRNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 3,
        title: const Text(
          "Quản lý thông báo",
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
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: const Text(
                  "Gửi thông báo theo vai trò",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PushNotificationToRolesScreen(token: widget.token),
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
                leading: const Icon(Icons.person_add_alt_1, color: Colors.green),
                title: const Text(
                  "Gửi thông báo cho 1 người dùng",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PushNotificationToUserScreen(token: widget.token),
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
