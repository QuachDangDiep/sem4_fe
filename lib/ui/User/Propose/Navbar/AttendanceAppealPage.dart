import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';

class AttendanceAppealPage extends StatefulWidget {
  final String token;

  const AttendanceAppealPage({Key? key, required this.token}) : super(key: key);

  @override
  State<AttendanceAppealPage> createState() => _AttendanceAppealPageState();
}

class _AttendanceAppealPageState extends State<AttendanceAppealPage> {
  String? employeeId;
  String? selectedAttendanceId;
  DateTime? selectedDate;
  File? selectedImage;
  final reasonController = TextEditingController();
  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchEmployeeIdAndAttendances();
  }

  Future<void> fetchEmployeeIdAndAttendances() async {
    try {
      final decoded = JwtDecoder.decode(widget.token);
      final userId = decoded['userId'] ?? decoded['sub'];

      final res = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        employeeId = res.body.trim();

        final attRes = await http.get(
          Uri.parse(Constants.attendancesByEmployeeUrl(employeeId!)),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (attRes.statusCode == 200) {
          final List data = jsonDecode(attRes.body);
          setState(() {
            attendanceList = data.map((e) {
              return {
                'attendanceId': e['attendanceId'],
                'attendanceDate': DateTime.parse(e['attendanceDate']),
              };
            }).toList();
          });
        }
      } else {
        throw Exception('Không lấy được employeeId');
      }
    } catch (e) {
      print('Lỗi khi lấy dữ liệu: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        final match = attendanceList.firstWhere(
              (e) =>
          DateFormat('yyyy-MM-dd').format(e['attendanceDate']) ==
              DateFormat('yyyy-MM-dd').format(picked),
          orElse: () => {},
        );
        selectedAttendanceId = match.isNotEmpty ? match['attendanceId'] : null;
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> submitAppeal() async {
    if (employeeId == null || selectedDate == null || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final requestBody = {
      'employeeId': employeeId,
      'attendanceId': selectedAttendanceId, // có thể null
      'reason': reasonController.text,
      'evidence': selectedImage != null ? base64Encode(selectedImage!.readAsBytesSync()) : '',
    };

    final response = await http.post(
      Uri.parse(Constants.postAttendanceAppealUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi giải trình thành công')),
      );
      setState(() {
        selectedDate = null;
        selectedAttendanceId = null;
        selectedImage = null;
        reasonController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi giải trình thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải trình chấm công'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn ngày muốn giải trình:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? 'Ngày đã chọn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                        : 'Chưa chọn ngày',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do giải trình',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Thêm hình ảnh'),
                ),
                const SizedBox(width: 12),
                if (selectedImage != null)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitAppeal,
                child: const Text('Gửi giải trình'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
