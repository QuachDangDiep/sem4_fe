import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';

class HRAttendanceAppealScreen extends StatefulWidget {
  final String token;

  const HRAttendanceAppealScreen({super.key, required this.token});

  @override
  State<HRAttendanceAppealScreen> createState() => _HRAttendanceAppealScreenState();
}

class _HRAttendanceAppealScreenState extends State<HRAttendanceAppealScreen> {
  late Future<List<Appeal>> _appeals;

  @override
  void initState() {
    super.initState();
    _appeals = fetchAllAppeals();
  }

  Future<List<Appeal>> fetchAllAppeals() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/api/attendance-appeals/all'), // Thay domain đúng
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      return jsonData.map((e) => Appeal.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tải đơn giải trình');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/api/attendance-appeals/$id/status'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
        'reviewedBy': getReviewerIdFromToken(widget.token), // Lấy ID người xét duyệt từ token
        'note': 'Xét duyệt bởi HR', // Có thể tùy chỉnh note
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));
      setState(() {
        _appeals = fetchAllAppeals();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${response.body}")));
    }
  }

// Hàm lấy ID người xét duyệt từ token (cần điều chỉnh theo cấu trúc token của bạn)
  String getReviewerIdFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return 'unknown';
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload['sub'] ?? 'unknown'; // Thay 'sub' bằng trường chứa ID trong token của bạn
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn giải trình (HR)'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Appeal>>(
        future: _appeals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          final appeals = snapshot.data!;
          if (appeals.isEmpty) return const Center(child: Text('Không có đơn giải trình nào'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: appeals.length,
            itemBuilder: (context, index) {
              final a = appeals[index];
              print('Evidence (first 100 chars): ${a.evidence.substring(0, a.evidence.length > 100 ? 100 : a.evidence.length)}');
              final statusColor = a.status == 'Approved'
                  ? Colors.green
                  : a.status == 'Rejected'
                  ? Colors.red
                  : Colors.orange;

              final statusBgColor = a.status == 'Approved'
                  ? Colors.green.shade50
                  : a.status == 'Rejected'
                  ? Colors.red.shade50
                  : Colors.orange.shade50;

// 👉 Thêm đoạn này ngay sau:
              final IconData statusIcon;
              final String statusText;

              if (a.status == 'Approved') {
                statusIcon = Icons.check_circle;
                statusText = 'Đã phê duyệt';
              } else if (a.status == 'Rejected') {
                statusIcon = Icons.cancel;
                statusText = 'Từ chối';
              } else {
                statusIcon = Icons.hourglass_top;
                statusText = 'Đang chờ';
              }

// Thay thế widget trong itemBuilder
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + Thông tin nhân viên
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 24,
                          child: Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.employeeName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('Mã NV: ${a.employeeId}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd/MM/yyyy HH:mm').format(a.appealDate),
                                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),

                    const Divider(height: 28, thickness: 0.8),

                    // Lý do giải trình
                    const Text('📌 Lý do giải trình',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(a.reason,
                        style: const TextStyle(fontSize: 15, color: Colors.black87)),

                    // Bằng chứng (nếu có)
                    if (a.evidence.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: const [
                                  Icon(Icons.image, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text("Bằng chứng",
                                      style: TextStyle(
                                          color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(base64Decode(
                                    a.evidence.contains(",")
                                        ? a.evidence.split(",")[1]
                                        : a.evidence)),
                              ),
                              actions: [
                                TextButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, color: Colors.orange),
                                  label: const Text("Đóng",
                                      style: TextStyle(
                                          color: Colors.orange, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.attach_file, color: Colors.orange),
                              SizedBox(width: 8),
                              Text("Xem hình ảnh",
                                  style: TextStyle(
                                      color: Colors.orange, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 6),
                          Text(statusText,
                              style: TextStyle(
                                  color: statusColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                    if (a.status == 'Pending') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => updateStatus(a.appealId, 'Approved'),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text("Phê duyệt"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => updateStatus(a.appealId, 'Rejected'),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text("Từ chối"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Appeal {
  final String appealId;
  final String employeeId;
  final String employeeName;
  final String reason;
  final String evidence;
  final DateTime appealDate;
  final String status;

  Appeal( {
    required this.appealId,
    required this.employeeName,
    required this.employeeId,
    required this.reason,
    required this.evidence,
    required this.appealDate,
    required this.status,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) => Appeal(
    appealId: json['appealId'],
    employeeId: json['employee']['employeeId'],
    employeeName: json['employee']['fullName'],
    reason: json['reason'],
    evidence: json['evidence'] ?? '',
    appealDate: DateTime.parse(json['appealDate']),
    status: json['status'],
  );
}