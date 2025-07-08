import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';

class ChangeShiftPage extends StatefulWidget {
  final String token;

  const ChangeShiftPage({super.key, required this.token});

  @override
  State<ChangeShiftPage> createState() => _ChangeShiftPageState();
}

class _ChangeShiftPageState extends State<ChangeShiftPage> {
  String? employeeId;
  String? selectedScheduleId;
  String? selectedScheduleInfoId;
  String? selectedWorkDay;

  List<Map<String, dynamic>> scheduleInfoOptions = [];
  List<Map<String, dynamic>> registeredSchedules = [];

  bool loading = false;

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
        await loadData();
      } else {
        throw Exception("❌ Không thể lấy employeeId");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lỗi khi lấy Employee ID")),
      );
    }
  }

  Future<void> loadData() async {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 7)).toIso8601String().split("T")[0];
      final to = now.add(const Duration(days: 30)).toIso8601String().split("T")[0];

      final registeredRes = await http.get(
        Uri.parse(Constants.workScheduleFilterRangeUrl(
          employeeId: employeeId!,
          fromDate: from,
          toDate: to,
        )),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      final scheduleInfoRes = await http.get(
        Uri.parse(Constants.workScheduleInfosUrl),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (registeredRes.statusCode == 200 && scheduleInfoRes.statusCode == 200) {
        final decodedRegistered = jsonDecode(registeredRes.body);
        final decodedScheduleInfo = jsonDecode(scheduleInfoRes.body);

        final regData = decodedRegistered['result'];
        final scheduleInfoData = decodedScheduleInfo['result'];

        setState(() {
          registeredSchedules = regData != null && regData is List
              ? List<Map<String, dynamic>>.from(regData)
              : [];

          scheduleInfoOptions = scheduleInfoData != null && scheduleInfoData is List
              ? List<Map<String, dynamic>>.from(scheduleInfoData)
              : [];
        });
      } else {
        throw Exception("Lỗi khi load dữ liệu");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lỗi khi load dữ liệu")),
      );
    }
  }

  void onScheduleSelected(String scheduleId) {
    final selected = registeredSchedules.firstWhere(
          (s) => s['scheduleId'] == scheduleId,
      orElse: () => {},
    );
    setState(() {
      selectedScheduleId = scheduleId;
      selectedScheduleInfoId = selected['scheduleInfoId'];
      selectedWorkDay = selected['workDay'];
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => selectedWorkDay = picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> handleSubmit() async {
    if (selectedScheduleId == null ||
        selectedScheduleInfoId == null ||
        selectedWorkDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗Vui lòng chọn đầy đủ thông tin")),
      );
      return;
    }

    final selectedInfo = scheduleInfoOptions.firstWhere(
          (e) => e['scheduleInfoId'] == selectedScheduleInfoId,
      orElse: () => {},
    );

    final defaultStart = selectedInfo['defaultStartTime'] ?? "08:00:00";
    final defaultEnd = selectedInfo['defaultEndTime'] ?? "17:00:00";

    setState(() => loading = true);

    final res = await http.put(
      Uri.parse(Constants.updateWorkScheduleUrl(selectedScheduleId!)),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "scheduleInfoId": selectedScheduleInfoId,
        "workDay": selectedWorkDay,
        "startTime": defaultStart,
        "endTime": defaultEnd,
        "status": "Active",
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("✅ Đổi ca thành công"),
          content: const Text("Bạn đã đổi ca thành công."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // đóng dialog
                Navigator.of(context).pop(); // quay lại trang trước
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Đổi ca thất bại")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đổi ca làm")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chọn ca muốn đổi:"),
            DropdownButtonFormField<String>(
              value: selectedScheduleId,
              items: registeredSchedules.map((s) {
                return DropdownMenuItem<String>(
                  value: s['scheduleId'],
                  child: Text('${s['scheduleInfoName'] ?? 'Không có tên'} - ${s['workDay']}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onScheduleSelected(val);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text("Chọn ca mới:"),
            DropdownButtonFormField<String>(
              value: selectedScheduleInfoId,
              items: scheduleInfoOptions.map((item) {
                return DropdownMenuItem<String>(
                  value: item['scheduleInfoId'],
                  child: Text(item['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedScheduleInfoId = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(selectedWorkDay ?? "Chọn ngày làm"),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleSubmit,
              child: const Text("Xác nhận đổi ca"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            )
          ],
        ),
      ),
    );
  }
}
