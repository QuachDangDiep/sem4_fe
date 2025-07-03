import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class WorkSchedule {
  final String scheduleId;
  final String employeeId;
  final String shiftName;
  final String workDay;
  final String startTime;
  final String endTime;
  final String status;

  WorkSchedule({
    required this.scheduleId,
    required this.employeeId,
    required this.shiftName,
    required this.workDay,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    String formatTime(String? value) {
      if (value == null) return '??:??';
      try {
        final parts = value.split('T');
        return parts.length == 2 ? parts[1].substring(0, 5) : value;
      } catch (e) {
        return '??:??';
      }
    }

    String formatDate(String? value) {
      if (value == null) return '??-??-????';
      try {
        final parts = value.split('T');
        return parts[0];
      } catch (e) {
        return value;
      }
    }

    return WorkSchedule(
      scheduleId: json['scheduleId'] ?? 'Không có ID',
      employeeId: json['employeeId'] ?? 'Không có ID nhân viên',
      shiftName: json['scheduleInfoId'] ?? 'Không rõ',
      workDay: formatDate(json['workDay']),
      startTime: formatTime(json['startTime']),
      endTime: formatTime(json['endTime']),
      status: json['status'] ?? 'Unknown',
    );
  }
}

class WorkScheduleScreen extends StatefulWidget {
  final String token;

  const WorkScheduleScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  late Future<WorkSchedule> futureSchedule;

  @override
  void initState() {
    super.initState();
    futureSchedule = fetchSchedule();
  }

  Future<WorkSchedule> fetchSchedule() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

      final res = await http.get(
        Uri.parse(Constants.workScheduleUrl),
        headers: headers,
      );

      print('Response body: ${res.body}');

      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);

        if (responseData['result'] is List) {
          final firstItem = responseData['result'][0];
          return WorkSchedule.fromJson(firstItem);
        } else if (responseData['result'] is Map) {
          return WorkSchedule.fromJson(responseData['result']);
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
      } else {
        throw Exception('Lỗi tải dữ liệu: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Color _getStatusColor(String status) {
    return status.toLowerCase() == 'active' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF57C00);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 4.0), // Reduced padding to move title closer
          child: Text(
            'Lịch Làm Việc',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                futureSchedule = fetchSchedule();
              });
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<WorkSchedule>(
        future: futureSchedule,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 80,
                    color: primaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể tải lịch làm việc',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        futureSchedule = fetchSchedule();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final schedule = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chi tiết ca làm việc',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(schedule.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            schedule.status,
                            style: TextStyle(
                              color: _getStatusColor(schedule.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),

                    // Schedule Details
                    _buildInfoRow(
                      icon: Icons.work,
                      label: 'Ca làm',
                      value: schedule.shiftName,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Ngày làm',
                      value: schedule.workDay,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Thời gian',
                      value: '${schedule.startTime} - ${schedule.endTime}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Mã nhân viên',
                      value: schedule.employeeId,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.confirmation_number,
                      label: 'Mã lịch',
                      value: schedule.scheduleId,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFF57C00),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}