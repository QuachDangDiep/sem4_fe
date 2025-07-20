import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class MyRequestsScreen extends StatefulWidget {
  final String token;

  const MyRequestsScreen({super.key, required this.token});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> allRequests = [];
  bool isLoading = true;
  String? _employeeId;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = widget.token;
      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) throw Exception('Không tìm thấy userId trong token');

      final empRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (empRes.statusCode != 200) throw Exception('Không lấy được employeeId');

      final employeeId = empRes.body.trim();
      _employeeId = employeeId;

      await _fetchData(token, employeeId);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _fetchData(String token, String employeeId, {String? status}) async {
    setState(() => isLoading = true);
    try {
      final leaveUrl = Uri.parse(Constants.leavesByEmployeeUrl(employeeId: employeeId, status: status));
      final appealUrl = Uri.parse(Constants.attendanceAppealsByEmployeeAndStatusUrl(employeeId: employeeId, status: status));

      final responses = await Future.wait([
        http.get(leaveUrl, headers: {'Authorization': 'Bearer $token'}),
        http.get(appealUrl, headers: {'Authorization': 'Bearer $token'}),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        throw Exception('Không thể tải dữ liệu');
      }

      final leaveList = jsonDecode(responses[0].body);
      final appealList = jsonDecode(responses[1].body);

      final allItems = <dynamic>[
        ...leaveList.map((e) => LeaveRequestModel.fromJson(e)),
        ...appealList.map((e) => AttendanceAppealModel.fromJson(e))
      ];

      setState(() {
        allRequests = allItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildLeaveCard(LeaveRequestModel leave) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Text(
                  'Đơn nghỉ phép',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                _buildStatusChip(leave.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('🗓 Từ: ${DateFormat('dd/MM/yyyy').format(leave.startDate)}'),
            Text('📅 Đến: ${DateFormat('dd/MM/yyyy').format(leave.endDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppealCard(AttendanceAppealModel appeal) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Text(
                  'Đơn giải trình',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                _buildStatusChip(appeal.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('📝 Lý do: ${appeal.reason}'),
            Text('📅 Ngày gửi: ${DateFormat('dd/MM/yyyy').format(appeal.createdAt)}'),
            if (appeal.reviewedBy != null)
              Text('👤 Duyệt bởi: ${appeal.reviewedBy!}'),
            if (appeal.reviewedAt != null)
              Text('🕒 Duyệt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(appeal.reviewedAt!)}'),
            if (appeal.note != null && appeal.note!.isNotEmpty)
              Text('🗒️ Ghi chú: ${appeal.note!}'),
            const SizedBox(height: 8),
            if (appeal.evidence != null && appeal.evidence!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Ảnh bằng chứng',style: TextStyle(color: Colors.orange)),
                        content: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(appeal.evidence!),
                            fit: BoxFit.contain,
                          ),
                        ),
                        actions: [
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Đóng'),
                            style: TextButton.styleFrom(foregroundColor: Colors.orange),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Xem bằng chứng'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }


  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn của tôi'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: DropdownButton<String>(
                hint: const Text("Chọn trạng thái"),
                value: selectedStatus,
                isExpanded: true,
                items: ['Approved', 'Pending', 'Rejected']
                    .map(
                      (status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                    _fetchData(widget.token, _employeeId!, status: value);
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allRequests.isEmpty
                ? const Center(child: Text('Không có đơn nào'))
                : ListView.builder(
              itemCount: allRequests.length,
              itemBuilder: (context, index) {
                final item = allRequests[index];
                if (item is LeaveRequestModel) {
                  return _buildLeaveCard(item);
                } else if (item is AttendanceAppealModel) {
                  return _buildAppealCard(item);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}

// ===== Models =====

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['leaveId'],
      employeeId: json['employeeId'].toString(),
      status: json['status'],
      startDate: DateTime.parse(json['leaveStartDate']),
      endDate: DateTime.parse(json['leaveEndDate']),
    );
  }
}

class AttendanceAppealModel {
  final String id;
  final String status;
  final String reason;
  final String? evidence;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? note;

  AttendanceAppealModel({
    required this.id,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.evidence,
    this.reviewedBy,
    this.reviewedAt,
    this.note,
  });

  factory AttendanceAppealModel.fromJson(Map<String, dynamic> json) {
    return AttendanceAppealModel(
      id: json['appealId'],
      status: json['status'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['appealDate']),
      evidence: json['evidence'],
      reviewedBy: json['reviewedBy']?['username'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      note: json['note'],
    );
  }
}
