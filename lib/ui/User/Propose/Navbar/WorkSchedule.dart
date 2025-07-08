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
  List<DateTime> weekDays = [];
  Map<String, Set<String>> selectedShiftsPerDay = {};
  Map<String, Set<String>> registeredShifts = {};
  List<dynamic> shiftInfos = [];
  bool isLoading = true;
  bool _hasRegisteredAnyShift = false;

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

        // ✅ Nếu đã đăng ký bất kỳ ca nào trong tuần → chuyển sang xem lịch
        if (_hasRegisteredAnyShift) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Thông báo"),
                content: const Text("Bạn đã đăng ký ca làm cho tuần này rồi.\nChuyển sang xem lịch làm việc?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Ở lại"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WorkSchedulePage(token: widget.token)),
                      );
                    },
                    child: const Text("Xem lịch"),
                  ),
                ],
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy employeeId: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadShiftInfos() async {
    _hasRegisteredAnyShift = false; // Đảm bảo reset

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

        final registered = await _fetchRegisteredShifts(formatted);
        registeredShifts[formatted] = registered;

        debugPrint("📅 $formatted - Số ca đã đăng ký: ${registered.length}");

        if (registered.isNotEmpty) {
          _hasRegisteredAnyShift = true;
        }
      }

      setState(() {});
    }
  }


  Future<Set<String>> _fetchRegisteredShifts(String date) async {
    final response = await http.get(
      Uri.parse("${Constants.workScheduleUrl}?empId=$employeeId&workDay=$date"), // 👈 sửa employeeId -> empId
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );



    final Set<String> result = {};
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] is List) {
        for (var item in data['result']) {
         // final scheduleInfo = item['scheduleInfo'];
          if (item['scheduleInfoId'] != null) {
            final shiftId = item['scheduleInfoId'];
            debugPrint("✅ Đã đăng ký shiftId: $shiftId vào ngày $date");
            result.add(shiftId);
          } else {
            debugPrint("⚠️ scheduleInfoId null: $item");
          }
        }
      }
    }
    return result;
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
          final workDay = DateTime.parse(date);
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
          debugPrint("Lỗi xử lý thời gian: $e");
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
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Đăng ký thành công"),
          content: const Text("Bạn đã đăng ký ca làm thành công. Bạn có muốn xem lịch làm việc không?"),
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
                  MaterialPageRoute(builder: (_) => WorkSchedulePage(token: widget.token)),
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

  Color _getShiftColor({required bool isRegistered, required bool isSelected}) {
    if (isRegistered) return Colors.grey.shade400;
    if (isSelected) return Colors.deepOrange;
    return Colors.orange.shade200;
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
    if (isLoading || shiftInfos.isEmpty || weekDays.isEmpty || employeeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đăng ký ca")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký ca làm theo tuần")),
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
                  Text("Ngày $formatted", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: shiftInfos.map((shift) {
                      final shiftId = shift['scheduleInfoId'];
                      final shiftName = shift['name'];
                      final start = _formatTime(shift['defaultStartTime']);
                      final end = _formatTime(shift['defaultEndTime']);
                      final isRegistered = registeredShifts[formatted]!.contains(shiftId);
                      final isSelected = selectedShiftsPerDay[formatted]!.contains(shiftId);

                      return FilterChip(
                        label: Text("$shiftName ($start - $end)"),
                        selected: isSelected,
                        onSelected: isRegistered ? null : (_) => _toggleShift(formatted, shiftId),
                        selectedColor: _getShiftColor(isRegistered: isRegistered, isSelected: isSelected),
                        backgroundColor: _getShiftColor(isRegistered: isRegistered, isSelected: isSelected),
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
          icon: const Icon(Icons.send),
          label: const Text("Đăng ký tất cả"),
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
