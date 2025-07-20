import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class PushNotificationToRolesScreen extends StatefulWidget {
  final String token;

  const PushNotificationToRolesScreen({Key? key, required this.token}) : super(key: key);

  @override
  _PushNotificationToRolesScreenState createState() => _PushNotificationToRolesScreenState();
}

class _PushNotificationToRolesScreenState extends State<PushNotificationToRolesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<String> selectedRoles = [];
  List<String> availableRoles = [];
  bool isLoading = false;
  String? userId;

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token không hợp lệ');
    }

    final payload = base64Url.normalize(parts[1]);
    final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));

    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Payload không hợp lệ');
    }

    return payloadMap;
  }

  Future<void> sendNotificationToRoles() async {
    final String apiUrl = '${Constants.baseUrl}/api/notify/push-to-roles';

    final Map<String, dynamic> body = {
      "title": _titleController.text,
      "message": _messageController.text,
      "sentBy": userId, // dùng userId đã decode từ token
      "roles": selectedRoles,
    };

    try {
      setState(() => isLoading = true);
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final result = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Gửi thành công: $result')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gửi thất bại: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e')),
      );
    }
  }

  Future<void> fetchRoles() async {
    final String apiUrl = '${Constants.baseUrl}/api/roles';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> rolesData = jsonResponse['result'];
        setState(() {
          availableRoles = rolesData.map<String>((item) => item['roleName'] as String).toList();
        });
      } else {
        throw Exception('Failed to load roles: ${response.body}');
      }
    } catch (e) {
      print('Error fetching roles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải vai trò: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRoles();
    final decodedToken = parseJwt(widget.token);
    userId = decodedToken['sub'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text(
          "Gửi thông báo theo vai trò",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Colors.grey[700]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Nội dung',
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Colors.grey[700]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
              ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chọn vai trò nhận thông báo:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: availableRoles.map((role) {
                final isSelected = selectedRoles.contains(role);
                return FilterChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      selected
                          ? selectedRoles.add(role)
                          : selectedRoles.remove(role);
                    });
                  },
                  selectedColor: Colors.orange.shade200,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : sendNotificationToRoles,
                icon: const Icon(Icons.send),
                label: Text(isLoading ? 'Đang gửi...' : 'Gửi thông báo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
