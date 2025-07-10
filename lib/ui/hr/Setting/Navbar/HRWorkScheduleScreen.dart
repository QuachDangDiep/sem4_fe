import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Setting/Navbar/WorkScheduleInfoDetailScreen.dart';

class HRWorkScheduleScreen extends StatefulWidget {
  final String token;

  const HRWorkScheduleScreen({super.key, required this.token});

  @override
  State<HRWorkScheduleScreen> createState() => _HRWorkScheduleScreenState();
}

class _HRWorkScheduleScreenState extends State<HRWorkScheduleScreen> {
  List<dynamic> workSchedules = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWorkSchedules();
  }

  Future<void> fetchWorkSchedules() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(Constants.workScheduleUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          workSchedules = json['result'] ?? [];
        });
      } else {
        showError("Không thể tải danh sách đăng ký ca làm.");
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

  String formatDate(String? dateStr) {
    if (dateStr == null) return '---';
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
  }

  String formatDateTime(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '---';
    try {
      final time = DateFormat.Hms().parse(isoStr);
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return 'Định dạng sai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách đăng ký ca làm"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workSchedules.isEmpty
          ? const Center(child: Text("Chưa có đăng ký nào"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workSchedules.length,
        itemBuilder: (context, index) {
          final schedule = workSchedules[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkScheduleInfoDetailScreen(
                    token: widget.token,
                    scheduleInfoId: schedule['scheduleInfoId'],
                  ),
                ),
              );
            },
            child: Card(
            elevation: 6,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: "🙋‍♂️ Tên nhân viên", value: schedule['employeeName']),
                  InfoRow(label: "👤 Mã nhân viên", value: schedule['employeeId']),
                  InfoRow(label: "📄 Mã ca", value: schedule['scheduleInfoId']),
                  InfoRow(label: "📅 Ngày làm", value: formatDate(schedule['workDay'])),
                  InfoRow(label: "🕒 Bắt đầu", value: formatDateTime(schedule['startTime'])),
                  InfoRow(label: "🕔 Kết thúc", value: formatDateTime(schedule['endTime'])),
                  InfoRow(label: "📌 Trạng thái", value: schedule['status']),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
            ),
            TextSpan(
              text: value ?? '---',
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}




