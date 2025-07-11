import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/WorkSchedulePage.dart';

class WeeklyShiftSelectionScreen extends StatefulWidget {
  final String token;

  const WeeklyShiftSelectionScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<WeeklyShiftSelectionScreen> createState() => _WeeklyShiftSelectionScreenState();
}

class _WeeklyShiftSelectionScreenState extends State<WeeklyShiftSelectionScreen> {
  String? employeeId;
  List<DateTime> nextDays = [];
  Map<String, Set<String>> selectedShiftsPerDay = {};
  List<dynamic> shiftInfos = [];
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

      if (userId == null) return;

      final res = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        employeeId = res.body.trim();
        debugPrint("📌 Employee ID hiện tại: $employeeId");
        await _loadShiftInfos();
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy employeeId: $e");
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
      shiftInfos = data['result'].where((shift) {
        final name = (shift['name'] ?? '').toString().toLowerCase();
        final desc = (shift['description'] ?? '').toString().toLowerCase();
        return name.contains('ot') || desc.contains('OT') || desc.contains('ngoài giờ');
      }).toList();


      List<DateTime> tempDays = [];
      final today = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final formatted = _formatDate(date);
        tempDays.add(date);
        selectedShiftsPerDay[formatted] = {};
      }
      nextDays = tempDays;
      setState(() {});
    }
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  void _toggleShift(String date, String shiftId) {
    final selected = selectedShiftsPerDay[date]!;
    if (selected.contains(shiftId)) {
      selected.remove(shiftId);
    } else {
      selected.add(shiftId);
    }
    setState(() {});
  }

  Future<void> _submitSelectedSchedules() async {
    if (employeeId == null) return;

    List<Map<String, dynamic>> payload = [];

    selectedShiftsPerDay.forEach((date, shiftSet) {
      for (var shiftId in shiftSet) {
        final info = shiftInfos.firstWhere((e) => e['scheduleInfoId'] == shiftId);
        final startTimeStr = info['defaultStartTime'];
        final endTimeStr = info['defaultEndTime'];

        try {
          final startParts = startTimeStr.split(':').map(int.parse).toList();
          final endParts = endTimeStr.split(':').map(int.parse).toList();

          final startTime = "${startParts[0].toString().padLeft(2, '0')}:${startParts[1].toString().padLeft(2, '0')}:${startParts[2].toString().padLeft(2, '0')}";
          final endTime = "${endParts[0].toString().padLeft(2, '0')}:${endParts[1].toString().padLeft(2, '0')}:${endParts[2].toString().padLeft(2, '0')}";

          payload.add({
            "employeeId": employeeId,
            "scheduleInfoId": shiftId,
            "workDay": date,
            "startTime": startTime,
            "endTime": endTime,
            "shiftType": "OT"
          });
        } catch (e) {
          debugPrint("Lỗi xử lý thời gian: $e");
        }
      }
    });

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn chưa chọn ca OT nào để đăng ký")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse(Constants.registerOvertimeUrl),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Đăng ký thành công"),
          content: const Text("Bạn đã đăng ký ca OT thành công. Bạn có muốn xem lịch làm việc không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Để sau"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => WeeklyShiftSelectionScreenHistory(token: widget.token)),
                );
              },
              child: const Text("Xem lịch"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng ký: ${response.statusCode}")),
      );
    }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(":");
      return "${parts[0]}:${parts[1]}";
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || shiftInfos.isEmpty || nextDays.isEmpty || employeeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đăng ký OT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký ca OT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: nextDays.map((date) {
          final formatted = _formatDate(date);
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ngày $formatted", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Column(
                    children: ([...shiftInfos]..sort((a, b) => a['defaultStartTime'].compareTo(b['defaultStartTime']))).map((shift) {
                      final shiftId = shift['scheduleInfoId'];
                      final shiftName = shift['name'];
                      final start = _formatTime(shift['defaultStartTime']);
                      final end = _formatTime(shift['defaultEndTime']);
                      final isSelected = selectedShiftsPerDay[formatted]!.contains(shiftId);

                      return GestureDetector(
                        onTap: () => _toggleShift(formatted, shiftId),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 1.2),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Icon(isSelected ? Icons.check_circle_outline : Icons.schedule, color: isSelected ? Colors.white : Colors.black87, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "$shiftName ($start - $end)",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -1), blurRadius: 8)],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _submitSelectedSchedules,
            icon: const Icon(Icons.check_circle, size: 24),
            label: const Text("Đăng ký OT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}
