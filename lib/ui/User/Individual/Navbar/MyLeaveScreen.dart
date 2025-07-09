import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class MyLeaveScreen extends StatefulWidget {
  final String token;
  const MyLeaveScreen({required this.token, super.key});

  @override
  State<MyLeaveScreen> createState() => _MyLeaveScreenState();
}

class _MyLeaveScreenState extends State<MyLeaveScreen> {
  List<LeaveRequestModel> leaves = [];
  bool isLoading = true;
  String? _token;
  String? _employeeId;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Token không tồn tại');

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) throw Exception('Không tìm thấy userId trong token');

      final empRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (empRes.statusCode != 200) {
        throw Exception('Không lấy được employeeId từ userId');
      }

      final employeeId = empRes.body.trim();
      setState(() {
        _token = token;
        _employeeId = employeeId;
      });

      await _fetchLeaves(token, employeeId);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _fetchLeaves(String token, String employeeId) async {
    final url = Uri.parse(Constants.myLeavesByEmployeeIdUrl(employeeId));
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔁 Status Code: ${response.statusCode}');
      print('📦 Raw Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['result'];

        if (data == null || data is! List) {
          throw Exception('❌ Dữ liệu không hợp lệ hoặc không có danh sách đơn nghỉ phép');
        }

        setState(() {
          leaves = data.map((e) => LeaveRequestModel.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('❌ Lỗi lấy dữ liệu: ${response.body}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: ${e.toString()}'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade100;
      case 'Pending':
        return Colors.orange.shade100;
      case 'Rejected':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_outline;
      case 'Pending':
        return Icons.hourglass_bottom;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn nghỉ phép của tôi'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaves.isEmpty
          ? const Center(child: Text('Không có đơn nghỉ phép nào'))
          : ListView.builder(
        itemCount: leaves.length,
        itemBuilder: (context, index) {
          final leave = leaves[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            color: Colors.white, // ✅ luôn trắng
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                _getStatusIcon(leave.status),
                color: Colors.deepOrange,
                size: 32,
              ),
              title: Text(
                '${leave.leaveType} (${leave.status})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 Từ ${DateFormat('dd/MM/yyyy').format(leave.leaveStartDate)} '
                          'đến ${DateFormat('dd/MM/yyyy').format(leave.leaveEndDate)}',
                    ),
                    const SizedBox(height: 4),
                    Text('👤 Mã nhân viên: ${leave.employeeId}'),
                    const SizedBox(height: 4),
                    Text('🟢 Trạng thái: ${_getStatusText(leave.status)}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Approved':
        return '✔️ Đã duyệt';
      case 'Pending':
        return '⏳ Đang chờ duyệt';
      case 'Rejected':
        return '❌ Từ chối';
      default:
        return status;
    }
  }
}

class LeaveRequestModel {
  final String leaveId;
  final String employeeId;
  final String leaveType;
  final String status;
  final String activeStatus;
  final DateTime leaveStartDate;
  final DateTime leaveEndDate;

  LeaveRequestModel({
    required this.leaveId,
    required this.employeeId,
    required this.leaveType,
    required this.status,
    required this.activeStatus,
    required this.leaveStartDate,
    required this.leaveEndDate,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      leaveId: json['leaveId'],
      employeeId: json['employeeId'].toString(),
      leaveType: json['leaveType'],
      status: json['status'],
      activeStatus: json['activeStatus'],
      leaveStartDate: DateTime.parse(json['leaveStartDate']),
      leaveEndDate: DateTime.parse(json['leaveEndDate']),
    );
  }
}
