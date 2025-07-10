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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.calendar_month, color: Colors.orange),
        title: Text('Đơn nghỉ phép (${leave.status})'),
        subtitle: Text(
          'Từ ${DateFormat('dd/MM/yyyy').format(leave.startDate)} đến ${DateFormat('dd/MM/yyyy').format(leave.endDate)}',
        ),
      ),
    );
  }

  Widget _buildAppealCard(AttendanceAppealModel appeal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.edit_note, color: Colors.blue),
            title: Text('Đơn giải trình (${appeal.status})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝 Lý do: ${appeal.reason}'),
                Text('📅 Ngày gửi: ${DateFormat('dd/MM/yyyy').format(appeal.createdAt)}'),
                if (appeal.reviewedBy != null)
                  Text('👤 Duyệt bởi: ${appeal.reviewedBy!}'),
                if (appeal.reviewedAt != null)
                  Text('🕒 Duyệt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(appeal.reviewedAt!)}'),
                if (appeal.note != null && appeal.note!.isNotEmpty)
                  Text('🗒️ Ghi chú: ${appeal.note!}'),
              ],
            ),
          ),
          if (appeal.evidence != null && appeal.evidence!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Ảnh bằng chứng'),
                      content: Image.memory(
                        base64Decode(appeal.evidence!),
                        fit: BoxFit.contain,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Đóng'),
                        )
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.image),
                label: Text('Xem bằng chứng'),
              ),
            ),
        ],
      ),
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
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              hint: const Text("Chọn trạng thái"),
              value: selectedStatus,
              isExpanded: true,
              items: ['Approved', 'Pending', 'Rejected']
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                  _fetchData(token, _employeeId!, status: value);
                });
              },
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
