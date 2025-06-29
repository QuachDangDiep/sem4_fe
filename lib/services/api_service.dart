import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class ApiService {
  static Future<void> sendFCMTokenToBackend(String userId, String token) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/api/token/save');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token đã gửi lên backend');
      } else {
        print('❌ Lỗi gửi token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối BE khi gửi token: $e');
    }
  }
}
