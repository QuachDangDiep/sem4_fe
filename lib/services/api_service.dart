import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class ApiService {
  static Future<void> sendFCMTokenToBackend(String userId, String fcmToken) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/api/fcm/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token đã gửi lên backend');
      } else {
        print('❌ Lỗi gửi token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi gửi token lên backend: $e');
    }
  }
}
