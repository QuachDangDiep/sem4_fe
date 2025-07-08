// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sem4_fe/Service/Constants.dart';

class WorkSchedulePage extends StatefulWidget {
  final String token;
  const WorkSchedulePage({Key? key, required this.token}) : super(key: key);

  @override
  State<WorkSchedulePage> createState() => _WorkSchedulePageState();
}

class _WorkSchedulePageState extends State<WorkSchedulePage> {
  String? employeeId;
  List<dynamic> schedules = [];
  bool isLoading = true;
  String selectedWeekLabel = "Tuần này";
  late List<Map<String, dynamic>> weekOptions;

  final notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _prepareWeekOptions();
    _initializeData();
  }

  void _initNotifications() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    notifications.initialize(const InitializationSettings(android: android));
  }

  void _prepareWeekOptions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    weekOptions = [
      {"label": "Tuần này", "from": startOfWeek, "to": endOfWeek},
      {
        "label": "Tuần trước",
        "from": startOfWeek.subtract(const Duration(days: 7)),
        "to": endOfWeek.subtract(const Duration(days: 7))
      },
      {
        "label": "Tuần 2 trước",
        "from": startOfWeek.subtract(const Duration(days: 14)),
        "to": endOfWeek.subtract(const Duration(days: 14))
      },
      {"label": "Tùy chọn", "from": null, "to": null},
      {
        "label": "Tất cả",
        "from": DateTime(2000),
        "to": DateTime.now().add(const Duration(days: 365))
      },
    ];
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
        final currentWeek = weekOptions.first;
        await _fetchScheduleByWeek(currentWeek['from'], currentWeek['to']);
        await _checkAndNotifyIfNoShiftToday();
      }
    } catch (_) {} finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchScheduleByWeek(DateTime from, DateTime to) async {
    if (employeeId == null) return;
    setState(() => isLoading = true);

    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;

    final url = Constants.workScheduleFilterRangeUrl(
      employeeId: employeeId!,
      fromDate: fromStr,
      toDate: toStr,
    );

    final res = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        schedules = data['result'] ?? [];
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _checkAndNotifyIfNoShiftToday() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final hasTodayShift = schedules.any((s) => s['workDay'].startsWith(today));

    if (!hasTodayShift) {
      const androidDetails = AndroidNotificationDetails(
        'no_shift_today',
        'Lịch làm việc',
        importance: Importance.high,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await notifications.show(
        0,
        'Không có lịch làm việc hôm nay',
        'Bạn có thể nghỉ hoặc kiểm tra lại',
        notificationDetails,
      );
    }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return timeStr;
    }
  }

  String _buildDetailedScheduleText(String workDayIso, String? defaultStart, String? defaultEnd, String? fallbackStart, String? fallbackEnd) {
    try {
      final day = DateTime.parse(workDayIso);
      final weekday = _getWeekday(day.weekday);
      final formattedDate = "${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}";
      final start = _formatTime(defaultStart ?? fallbackStart ?? '');
      final end = _formatTime(defaultEnd ?? fallbackEnd ?? '');
      return "$weekday, $formattedDate\n$start - $end";
    } catch (_) {
      return "Không rõ ngày/giờ";
    }
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Thứ 2";
      case DateTime.tuesday:
        return "Thứ 3";
      case DateTime.wednesday:
        return "Thứ 4";
      case DateTime.thursday:
        return "Thứ 5";
      case DateTime.friday:
        return "Thứ 6";
      case DateTime.saturday:
        return "Thứ 7";
      case DateTime.sunday:
        return "Chủ nhật";
      default:
        return "";
    }
  }

  Future<void> _exportToPDF() async {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có dữ liệu để xuất PDF")),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: schedules.map((item) {
            return pw.Text(
              "Ca: ${item['scheduleInfoName']} | " +
                  _buildDetailedScheduleText(
                    item['workDay'],
                    item['defaultStartTime'],
                    item['defaultEndTime'],
                    item['startTime'],
                    item['endTime'],
                  ),
            );
          }).toList(),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _savePDFToFile() async {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có dữ liệu để lưu PDF")),
      );
      return;
    }

    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: schedules.map((item) {
            return pw.Text(
              "Ca: ${item['scheduleInfoName']} | " +
                  _buildDetailedScheduleText(
                    item['workDay'],
                    item['defaultStartTime'],
                    item['defaultEndTime'],
                    item['startTime'],
                    item['endTime'],
                  ),
            );
          }).toList(),
        ),
      ),
    );

    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/lich_lam_viec.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã lưu: ${file.path}")),
    );
  }

  Widget _buildWeekSelector() {
    return DropdownButton<String>(
      value: selectedWeekLabel,
      isExpanded: true,
      items: weekOptions.map((week) {
        return DropdownMenuItem<String>(
          value: week['label'],
          child: Text(week['label']),
        );
      }).toList(),
      onChanged: (value) async {
        if (value != null) {
          setState(() => selectedWeekLabel = value);

          if (value == "Tùy chọn") {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2022),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              await _fetchScheduleByWeek(picked.start, picked.end);
            }
          } else {
            final selected = weekOptions.firstWhere((w) => w['label'] == value);
            await _fetchScheduleByWeek(selected['from'], selected['to']);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch làm việc"), backgroundColor: Colors.deepOrange),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: _buildWeekSelector()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Xem PDF"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _savePDFToFile,
                  icon: const Icon(Icons.download),
                  label: const Text("Tải về"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : schedules.isEmpty
                ? const Center(
              child: Text("⚠️ Tuần này bạn không có lịch làm việc nào.",
                  style: TextStyle(fontSize: 16, color: Colors.red)),
            )
                : ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final item = schedules[index];
                return ListTile(
                  title: Text(item['scheduleInfoName'] ?? "Chưa rõ ca"),
                  subtitle: Text(
                    _buildDetailedScheduleText(
                      item['workDay'],
                      item['defaultStartTime'],
                      item['defaultEndTime'],
                      item['startTime'],
                      item['endTime'],
                    ),
                  ),
                  leading: const Icon(Icons.schedule, color: Colors.deepOrange),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
