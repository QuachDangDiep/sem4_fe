import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';

class WeeklyShiftSelectionScreen extends StatefulWidget {
  final String token;

  const WeeklyShiftSelectionScreen({
    required this.token,
  });

  @override
  State<WeeklyShiftSelectionScreen> createState() => _WeeklyShiftSelectionScreenState();
}

class _WeeklyShiftSelectionScreenState extends State<WeeklyShiftSelectionScreen> {
  String? employeeId;
  List<DateTime> weekDays = [];
  Map<String, Set<String>> selectedShiftsPerDay = {}; // date -> selected shifts
  Map<String, Set<String>> registeredShifts = {};     // date -> already registered
  List<dynamic> shiftInfos = []; // get from backend
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final decoded = JwtDecoder.decode(widget.token);
      final userId = decoded['userId'];

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy userId trong token")),
        );
        return;
      }

      final res = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        // ❗ SỬA Ở ĐÂY
        employeeId = res.body.trim(); // Loại bỏ jsonDecode, xử lý UUID trực tiếp
        await _loadShiftInfos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi lấy employeeId: ${res.statusCode}")),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _loadShiftInfos() async {
    final response = await http.get(
      Uri.parse(Constants.workScheduleInfosUrl),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200 && employeeId != null) {
      final data = jsonDecode(response.body);
      shiftInfos = data['result'];

      final today = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final formatted = _formatDate(date);
        weekDays.add(date);
        selectedShiftsPerDay[formatted] = {};
        registeredShifts[formatted] = await _fetchRegisteredShifts(formatted);
      }

      setState(() {});
    } else {
      print("❌ Error fetching shifts or employeeId is null");
    }
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<Set<String>> _fetchRegisteredShifts(String date) async {
    final response = await http.get(
      Uri.parse("${Constants.workScheduleUrl}?employeeId=$employeeId&workDay=$date"),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    final Set<String> result = {};
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] is List) {
        for (var item in data['result']) {
          final shiftId = item['scheduleInfo']['scheduleInfoId'];
          result.add(shiftId);
        }
      }
    }
    return result;
  }

  void _toggleShift(String date, String shiftId) {
    final selected = selectedShiftsPerDay[date]!;
    if (selected.contains(shiftId)) {
      selected.remove(shiftId);
    } else {
      selected.add(shiftId);
    }
    setState(() {});
  }

  Color _getShiftColor({required bool isRegistered, required bool isSelected}) {
    if (isRegistered) return Colors.grey.shade400;
    if (isSelected) return Colors.deepOrange;
    return Colors.orange.shade200;
  }

  String extractTime(String? datetimeStr) {
    if (datetimeStr == null) return '';
    final parts = datetimeStr.split("T");
    return parts.length > 1 ? parts[1] : '';
  }

  Future<void> _submitSelectedSchedules() async {
    if (employeeId == null) return;

    List<Map<String, dynamic>> payload = [];

    selectedShiftsPerDay.forEach((date, shiftSet) {
      for (var shiftId in shiftSet) {
        final info = shiftInfos.firstWhere((e) => e['scheduleInfoId'] == shiftId);

        final startTimeStr = info['defaultStartTime']; // e.g., "08:00:00"
        final endTimeStr = info['defaultEndTime'];     // e.g., "12:00:00"

        // Chuyển `date` (yyyy-MM-dd) + time => ISO datetime
        try {
          final workDay = DateTime.parse(date); // yyyy-MM-dd
          final startParts = startTimeStr.split(':').map(int.parse).toList();
          final endParts = endTimeStr.split(':').map(int.parse).toList();

          final startTime = DateTime(
            workDay.year,
            workDay.month,
            workDay.day,
            startParts[0],
            startParts[1],
            startParts[2],
          ).toIso8601String();

          final endTime = DateTime(
            workDay.year,
            workDay.month,
            workDay.day,
            endParts[0],
            endParts[1],
            endParts[2],
          ).toIso8601String();

          payload.add({
            "employeeId": employeeId,
            "scheduleInfoId": shiftId,
            "workDay": date,
            "startTime": startTime,
            "endTime": endTime,
            "status": "Active",
          });
        } catch (e) {
          print("❌ Lỗi khi xử lý thời gian: $e");
        }
      }
    });

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn chưa chọn ca nào hợp lệ để đăng ký")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("${Constants.baseUrl}/api/work-schedules/bulk"),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${response.statusCode}")),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    if (isLoading || shiftInfos.isEmpty || weekDays.isEmpty || employeeId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Đăng ký ca")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Đăng ký ca làm theo tuần")),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: weekDays.map((date) {
          final formatted = _formatDate(date);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ngày $formatted", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: shiftInfos.map((shift) {
                      final shiftId = shift['scheduleInfoId'];
                      final shiftName = shift['name'];
                      final isRegistered = registeredShifts[formatted]!.contains(shiftId);
                      final isSelected = selectedShiftsPerDay[formatted]!.contains(shiftId);

                      return FilterChip(
                        label: Text(shiftName),
                        selected: isSelected,
                        onSelected: isRegistered
                            ? null
                            : (_) => _toggleShift(formatted, shiftId),
                        selectedColor: _getShiftColor(
                          isRegistered: isRegistered,
                          isSelected: isSelected,
                        ),
                        backgroundColor: _getShiftColor(
                          isRegistered: isRegistered,
                          isSelected: isSelected,
                        ),
                        labelStyle: TextStyle(
                          color: isRegistered ? Colors.black38 : Colors.black,
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _submitSelectedSchedules,
          icon: Icon(Icons.send),
          label: Text("Đăng ký tất cả"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
