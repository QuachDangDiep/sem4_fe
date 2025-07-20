import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class PushNotificationToUserScreen extends StatefulWidget {
  final String token;

  const PushNotificationToUserScreen({Key? key, required this.token}) : super(key: key);

  @override
  _PushNotificationToUserScreenState createState() => _PushNotificationToUserScreenState();
}

class _PushNotificationToUserScreenState extends State<PushNotificationToUserScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<User> users = [];
  User? selectedUser;
  bool isLoading = false;
  String? senderId;

  @override
  void initState() {
    super.initState();
    _fetchSenderId();
    fetchUsers();
  }

  Future<void> _fetchSenderId() async {
    try {
      final parts = widget.token.split('.');
      if (parts.length != 3) {
        throw Exception('Token không đúng định dạng JWT');
      }
      final payload = base64.normalize(parts[1]);
      final decoded = json.decode(utf8.decode(base64.decode(payload)));
      print('Decoded token payload: $decoded');
      setState(() {
        senderId = decoded['userId'] ?? decoded['sub'];
        if (senderId == null) {
          throw Exception('Không tìm thấy userId hoặc sub trong token');
        }
      });
      print('Sender ID: $senderId');
    } catch (e, stackTrace) {
      print('Error decoding token: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi giải mã token: $e')),
      );
    }
  }

  Future<void> fetchUsers() async {
    const url = '${Constants.baseUrl}/api/users';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Users API response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> userList = data['result'];
        setState(() {
          users = userList.map((e) => User.fromJson(e)).toList();
        });
        print('Fetched users: ${users.map((u) => {"id": u.userId, "username": u.username}).toList()}');
      } else {
        throw Exception('Không thể tải danh sách người dùng: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error fetching users: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách người dùng: $e')),
      );
    }
  }

  Future<void> sendNotificationToUser() async {
    final String apiUrl = '${Constants.baseUrl}/api/notify/push-to-user';

    if (senderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi: Không lấy được ID người gửi')),
      );
      return;
    }

    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Vui lòng chọn người nhận')),
      );
      return;
    }

    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Vui lòng nhập tiêu đề và nội dung')),
      );
      return;
    }

    final Map<String, String> body = {
      "userId": selectedUser!.userId, // Trường userId cho người nhận
      "senderId": senderId!,      // Trường senderId cho người gửi
      "title": _titleController.text,
      "message": _messageController.text,
    };

    try {
      setState(() => isLoading = true);
      print('Sending notification to: $apiUrl');
      print('Request body: $body');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );
      print('Response: ${response.statusCode} - ${response.body}');
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Gửi thông báo thành công')),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() => selectedUser = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gửi thất bại: ${response.body}')),
        );
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      print('Error sending notification: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi khi gửi thông báo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Gửi thông báo cho người dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<User>(
              value: selectedUser,
              decoration: InputDecoration(
                labelText: 'Chọn người dùng',
                labelStyle: const TextStyle(color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              hint: const Text('Chọn người nhận'),
              items: users.map((user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text(user.username),
                );
              }).toList(),
              onChanged: (user) {
                setState(() {
                  selectedUser = user;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                labelStyle: const TextStyle(color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Nội dung',
                labelStyle: const TextStyle(color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading || selectedUser == null || senderId == null ? null : sendNotificationToUser,
                icon: const Icon(Icons.send),
                label: Text(isLoading ? 'Đang gửi...' : 'Gửi thông báo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class User {
  final String userId;
  final String username;

  User({required this.userId, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Không có tên',
    );
  }
}