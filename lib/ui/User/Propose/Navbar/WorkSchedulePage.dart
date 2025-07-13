import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:table_calendar/table_calendar.dart';

class WeeklyShiftSelectionScreenHistory extends StatefulWidget {
  final String token;

  const WeeklyShiftSelectionScreenHistory({Key? key, required this.token}) : super(key: key);

  @override
  State<WeeklyShiftSelectionScreenHistory> createState() => _WeeklyShiftSelectionScreenHistoryState();
}

class _WeeklyShiftSelectionScreenHistoryState extends State<WeeklyShiftSelectionScreenHistory> {
  String? employeeId;
  List<dynamic> registeredSchedules = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();

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
        debugPrint("📌 Employee ID: $employeeId");
        await _loadRegisteredSchedules();
      }
    } catch (e) {
      debugPrint("❌ Lỗi khi lấy employeeId: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadRegisteredSchedules() async {
    if (employeeId == null) return;
    final fromStr = DateTime(2022).toIso8601String().split('T').first;
    final toStr = DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T').first;
    final url = Constants.workSchedulesByDateRangeUrl(
      employeeId: employeeId!,
      fromDate: fromStr,
      toDate: toStr,
    );

    final res = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer ${widget.token}'});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> rawSchedules = data['result'] ?? [];

      rawSchedules.sort((a, b) {
        final dateA = DateTime.tryParse(a['workDay']) ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['workDay']) ?? DateTime(2000);
        return dateA.compareTo(dateB);
      });

      setState(() {
        registeredSchedules = rawSchedules;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final result = registeredSchedules.where((e) {
      final date = DateTime.tryParse(e['workDay']);
      final isMatch = date != null && isSameDay(date, day);
      if (isMatch) {
        debugPrint("🎯 ${e['workDay']} | ${e['shiftType']} | ${e['status']}");
      }
      return isMatch;
    }).toList();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch làm việc theo ngày", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: TableCalendar(
          locale: 'vi_VN',
          firstDay: DateTime.utc(2022, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          eventLoader: _getEventsForDay,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty && (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday)) {
                return const Center(
                  child: Text('OFF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                );
              } else if (events.isNotEmpty) {
                final hasNormal = events.any((event) {
                  final e = event as Map<String, dynamic>;
                  final type = (e['shiftType'] ?? e['scheduleInfoName'])?.toString().toLowerCase() ?? '';
                  final status = e['status']?.toString().toLowerCase() ?? '';
                  return type == 'normal' && status == 'active';
                });

                final hasApprovedOT = events.any((event) {
                  final e = event as Map<String, dynamic>;
                  final type = (e['shiftType'] ?? e['scheduleInfoName'])?.toString().toLowerCase() ?? '';
                  final status = e['status']?.toString().toLowerCase() ?? '';
                  return type == 'ot' && status == 'active';
                });

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasNormal)
                        const Icon(Icons.circle, color: Colors.green, size: 10),
                      if (hasApprovedOT)
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                    ],
                  ),
                );
              }
              return null;
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() => _focusedDay = focusedDay);
            final events = _getEventsForDay(selectedDay);
            if (events.isNotEmpty) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Chi tiết ca làm'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((e) {
                      final type = (e['shiftType'] ?? e['scheduleInfoName'])?.toString().toLowerCase() ?? '';
                      final status = e['status']?.toString().toLowerCase() ?? '';
                      final isOT = (type == 'ot') && status == 'active';

                      return ListTile(
                        title: Text("Ca: ${e['scheduleInfoName'] ?? "Không rõ"}"),
                        subtitle: Text("Giờ: ${_formatTime(e['startTime'])} - ${_formatTime(e['endTime'])}"),
                        trailing: isOT ? const Icon(Icons.star, color: Colors.orange) : null,
                      );
                    }).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    )
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "--:--";
    try {
      final parts = timeStr.split(":");
      return "${parts[0]}:${parts[1]}";
    } catch (_) {
      return timeStr;
    }
  }
}
