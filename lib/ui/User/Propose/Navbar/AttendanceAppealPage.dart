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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // Màu cam cho header
              onPrimary: Colors.white, // Chữ trắng trên header
              onSurface: Colors.black, // Chữ chính trong dialog
            ),
            dialogBackgroundColor: Colors.white, // Nền trắng
          ),
          child: child!,
        );
      },
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
        title: const Text('Giải trình chấm công',style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Chọn ngày muốn giải trình:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? '🗓️ Ngày đã chọn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                          : '⚠️ Chưa chọn ngày',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Chọn ngày'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📝 Lý do giải trình:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Nhập lý do...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Thêm hình ảnh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                if (selectedImage != null)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitAppeal,
                icon: const Icon(Icons.send),
                label: const Text('Gửi giải trình'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
