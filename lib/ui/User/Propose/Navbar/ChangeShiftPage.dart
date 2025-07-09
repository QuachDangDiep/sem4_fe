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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // Màu cam header và button
              onPrimary: Colors.white, // Chữ trên header
              onSurface: Colors.black, // Chữ chính
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange, // Màu của nút Cancel / OK
              ),
            ),
            dialogBackgroundColor: Colors.white, // Nền trắng
          ),
          child: child!,
        );
      },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text(
                "Đổi ca thành công",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Bạn đã đổi ca thành công.",
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Đóng dialog
                    Navigator.of(context).pop(); // Quay lại
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
      appBar: AppBar(
        title: const Text(
          "Đổi ca làm",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // ✅ Căn giữa tiêu đề
        backgroundColor: Colors.orange, // ✅ Màu nền cam
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "1. Ca hiện tại",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedScheduleId,
                  items: registeredSchedules.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['scheduleId'],
                      child: Text(
                        '${s['scheduleInfoName'] ?? 'Không rõ'} - ${s['workDay']}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onScheduleSelected(val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Chọn ca hiện tại",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.orange),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "2. Chọn ca mới",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedScheduleInfoId,
                      items: scheduleInfoOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['scheduleInfoId'],
                          child: Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedScheduleInfoId = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "3. Chọn ngày làm mới",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              selectedWorkDay ?? "Chọn ngày làm",
                              style: TextStyle(
                                fontSize: 15,
                                color: selectedWorkDay == null ? Colors.grey : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_today, color: Colors.orange),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: handleSubmit,
                icon: const Icon(Icons.swap_horiz, size: 22),
                label: const Text(
                  "Xác nhận đổi ca",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
