import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class WorkScheduleInfoDetailScreen extends StatefulWidget {
  final String token;
  final String scheduleInfoId;

  const WorkScheduleInfoDetailScreen({
    super.key,
    required this.token,
    required this.scheduleInfoId,
  });

  @override
  State<WorkScheduleInfoDetailScreen> createState() => _WorkScheduleInfoDetailScreenState();
}

class _WorkScheduleInfoDetailScreenState extends State<WorkScheduleInfoDetailScreen> {
  Map<String, dynamic>? scheduleInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchScheduleInfo();
  }

  Future<void> fetchScheduleInfo() async {
    try {
      print("Fetching scheduleInfo with id: ${widget.scheduleInfoId}");

      final res = await http.get(
        Uri.parse('${Constants.baseUrl}/api/work-schedule-infos/${widget.scheduleInfoId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print("Response body: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          scheduleInfo = json['result'];
        });
      } else {
        showError("Không thể tải thông tin chi tiết.");
      }
    } catch (e) {
      showError("Lỗi kết nối: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "---";
    try {
      final time = TimeOfDay.fromDateTime(DateTime.parse("1970-01-01T$timeStr"));
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return timeStr; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết ca làm"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : scheduleInfo == null
          ? const Center(child: Text("Không có dữ liệu"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  label: "Mã ca",
                  value: scheduleInfo!['scheduleInfoId'],
                  icon: Icons.qr_code,
                ),
                InfoRow(
                  label: "Tên ca",
                  value: scheduleInfo!['name'],
                  icon: Icons.badge,
                ),
                InfoRow(
                  label: "Mô tả",
                  value: scheduleInfo!['description'],
                  icon: Icons.description,
                ),
                InfoRow(
                  label: "Giờ bắt đầu",
                  value: formatTime(scheduleInfo!['defaultStartTime']),
                  icon: Icons.schedule,
                  iconColor: Colors.green,
                ),
                InfoRow(
                  label: "Giờ kết thúc",
                  value: formatTime(scheduleInfo!['defaultEndTime']),
                  icon: Icons.schedule_outlined,
                  iconColor: Colors.red,
                ),
                InfoRow(
                  label: "Trạng thái",
                  value: scheduleInfo!['status'],
                  icon: Icons.toggle_on,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color iconColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? "---",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}
