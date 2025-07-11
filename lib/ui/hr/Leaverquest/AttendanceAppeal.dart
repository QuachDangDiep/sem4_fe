import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';

class AttendanceAppeal {
  final String appealId;
  final String employeeId;
  final String employeeName; // thêm dòng này
  final String reason;
  final String evidence;
  final DateTime appealDate;
  final String status;

  AttendanceAppeal({
    required this.appealId,
    required this.employeeId,
    required this.employeeName,
    required this.reason,
    required this.evidence,
    required this.appealDate,
    required this.status,
  });

  factory AttendanceAppeal.fromJson(Map<String, dynamic> json, {String? employeeName}) {
    return AttendanceAppeal(
      appealId: json['appealId'],
      employeeId: json['employee']['employeeId'],
      employeeName: employeeName ?? 'Unknown', // dùng nếu đã fetch
      reason: json['reason'],
      evidence: json['evidence'] ?? '',
      appealDate: DateTime.parse(json['appealDate']),
      status: json['status'],
    );
  }
}

class AttendanceAppealScreen extends StatefulWidget {
  final String token;

  const AttendanceAppealScreen({super.key, required this.token});

  @override
  State<AttendanceAppealScreen> createState() => _AttendanceAppealScreenState();
}

class _AttendanceAppealScreenState extends State<AttendanceAppealScreen> {
  late Future<List<AttendanceAppeal>> _futureAppeals;

  @override
  void initState() {
    super.initState();
    _futureAppeals = fetchAttendanceAppeals();
  }

  Future<List<AttendanceAppeal>> fetchAttendanceAppeals() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/api/attendance-appeals/all'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json is List ? json : (json['data'] ?? []);
      return data.map((e) => AttendanceAppeal.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách giải trình: ${response.statusCode}');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/api/attendance-appeals/$id/status'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'status': status,
        'reviewedBy': 'admin-id', // Cập nhật theo user thực tế
        'note': 'Reviewed by HR',
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
      setState(() {
        _futureAppeals = fetchAttendanceAppeals();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response.body}')),
      );
    }
  }

  Future<String> fetchEmployeeName(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data']?['fullName']?.toString() ??
            jsonData['result']?['fullName']?.toString() ??
            'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      print('Error fetching employee name for $employeeId: $e');
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn giải trình'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: FutureBuilder<List<AttendanceAppeal>>(
        future: _futureAppeals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final appeals = snapshot.data!;
          if (appeals.isEmpty) {
            return const Center(child: Text('Không có đơn giải trình nào.'));
          }
          return ListView.builder(
            itemCount: appeals.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final appeal = appeals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: Colors.grey.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhân viên: ${appeal.employeeName} (${appeal.employeeId})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(appeal.appealDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Lý do:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(appeal.reason, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      if (appeal.evidence.isNotEmpty) ...[
                        Text('Bằng chứng:', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(appeal.evidence, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                      ],
                      const Divider(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: appeal.status == 'Approved'
                                  ? Colors.green.shade100
                                  : appeal.status == 'Rejected'
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              appeal.status,
                              style: TextStyle(
                                color: appeal.status == 'Approved'
                                    ? Colors.green
                                    : appeal.status == 'Rejected'
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (appeal.status == 'Pending')
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  label: const Text("Duyệt", style: TextStyle(color: Colors.green)),
                                  onPressed: () => updateStatus(appeal.appealId, 'Approved'),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  label: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                                  onPressed: () => updateStatus(appeal.appealId, 'Rejected'),
                                ),
                              ],
                            )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
