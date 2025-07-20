import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';

class EmployeeHistoryByHrScreen extends StatefulWidget {
  final String employeeId;
  final String token;

  const EmployeeHistoryByHrScreen({
    Key? key,
    required this.employeeId,
    required this.token,
  }) : super(key: key);

  @override
  State<EmployeeHistoryByHrScreen> createState() => _EmployeeHistoryByHrScreenState();
}

class _EmployeeHistoryByHrScreenState extends State<EmployeeHistoryByHrScreen> {
  List<dynamic> _employeeHistories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkTokenValidity();
    _fetchEmployeeHistory();
  }

  void _checkTokenValidity() {
    try {
      bool isExpired = JwtDecoder.isExpired(widget.token);
      Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.token);
      print('Token expired: $isExpired');
      print('Decoded token: $decodedToken');
      String role = decodedToken['role']?.toString() ?? 'Unknown';
      print('User role: $role');
    } catch (e) {
      print('Lỗi giải mã token: $e');
    }
  }

  Future<void> _fetchEmployeeHistory() async {
    final url = Uri.parse(
      '${Constants.baseUrl}/api/employee-histories/employee/${widget.employeeId}',
    );
    print('EMPLOYEE ID: ${widget.employeeId}');
    print('Authorization header: Bearer ${widget.token}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _employeeHistories = data['result'] ?? []; // Lấy từ 'result'
          _isLoading = false;
        });
      } else {
        print('Lỗi khi gọi API: ${response.body}');
        setState(() {
          _errorMessage = 'Lỗi ${response.statusCode}: ${json.decode(response.body)['message'] ?? 'Không xác định'}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    final status = history['status'] ?? 'Không xác định';
    final isActive = status == 'Active';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work_outline, color: Colors.orange, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    history['positionName'] ?? 'Không có',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isActive ? 'Đang làm' : 'Nghỉ việc',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.apartment, 'Phòng ban', history['departmentName'] ?? 'Không có'),
            _infoRow(Icons.calendar_today, 'Từ ngày', history['startDate'] ?? 'Không có'),
            _infoRow(Icons.event_busy, 'Đến ngày', history['endDate'] ?? 'Hiện tại'),
            _infoRow(Icons.info_outline, 'Lý do', history['reason'] ?? 'Không có'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử làm việc nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _employeeHistories.isEmpty
          ? const Center(child: Text('Không có lịch sử làm việc'))
          : ListView.builder(
        itemCount: _employeeHistories.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(_employeeHistories[index] as Map<String, dynamic>);
        },
      ),
    );
  }
}

Widget _infoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(top: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    ),
  );
}

