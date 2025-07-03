import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';

class WorkHistoryScreen extends StatefulWidget {
  final String token;

  const WorkHistoryScreen({Key? key, required this.token}) : super(key: key);

  @override
  _WorkHistoryScreenState createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  List<EmployeeHistoryResponse> _workHistoryList = [];
  bool _isLoading = true;
  String? _employeeId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployeeIdAndFetchHistory();
  }

  Future<void> _loadEmployeeIdAndFetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _employeeId = prefs.getString('employeeId');

      if (_employeeId == null) {
        // Nếu chưa có employeeId, lấy từ API
        final token = prefs.getString('auth_token');
        if (token == null) throw Exception('Token không tồn tại');

        final decoded = JwtDecoder.decode(token);
        final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
        if (userId == null) throw Exception('Không tìm thấy userId trong token');

        final response = await http.get(
          Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          _employeeId = response.body.trim();
          await prefs.setString('employeeId', _employeeId!);
        } else {
          throw Exception('Không lấy được employeeId');
        }
      }

      await _fetchWorkHistory();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải lịch sử làm việc: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWorkHistory() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.employeeHistoriesUrl),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      debugPrint('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['code'] == 200) {
          final List<dynamic> historyData = data['result'] ?? [];

          debugPrint('Raw data: ${historyData.toString()}');

          setState(() {
            _workHistoryList = historyData.map((json) {
              try {
                return EmployeeHistoryResponse.fromJson(json);
              } catch (e, stackTrace) {
                debugPrint('Error parsing item: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint('Problematic item: $json');

                // Fallback để vẫn hiển thị dữ liệu dù có lỗi parse
                return EmployeeHistoryResponse(
                  historyId: json['historyId'] ?? json['historyID'] ?? 'unknown',
                  employeeId: json['employeeId'] ?? json['employedId'] ?? 'unknown',
                  employeeName: json['employeeName'] ?? json['employesName'],
                  departmentId: json['departmentId'],
                  departmentName: json['departmentName'],
                  positionId: json['positionId'],
                  positionName: json['positionName'] ?? json['position'],
                  startDate: json['startDate'] ?? '1970-01-01',
                  endDate: json['endDate'],
                  reason: json['reason'],
                  status: json['status'] ?? 'Inactive',
                );
              }
            }).toList();
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Lỗi không xác định');
        }
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error details: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm việc'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _workHistoryList.isEmpty
          ? const Center(child: Text('Không có dữ liệu lịch sử làm việc'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _workHistoryList.length,
        itemBuilder: (context, index) {
          final history = _workHistoryList[index];
          return _buildHistoryCard(history);
        },
      ),
    );
  }

  Widget _buildHistoryCard(EmployeeHistoryResponse history) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    DateTime? startDate;
    DateTime? endDate;

    try {
      startDate = DateTime.parse(history.startDate);
    } catch (e) {
      startDate = DateTime(1970);
    }

    try {
      endDate = history.endDate != null ? DateTime.parse(history.endDate!) : null;
    } catch (e) {
      endDate = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: history.status == 'Active'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: history.status == 'Active'
                      ? Colors.green
                      : Colors.red,
                  radius: 4,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    history.employeeName ?? 'Không có tên',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  history.status == 'Active' ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: history.status == 'Active'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Department and Position
                _buildDetailItem(
                  Icons.apartment,
                  'Phòng ban',
                  history.departmentName ?? 'Chưa cập nhật',
                  iconColor: Color(0xFFFF9800), // màu chủ đạo
                ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  Icons.badge,
                  'Chức vụ',
                  history.positionName ?? 'Chưa cập nhật',
                  iconColor: Color(0xFFFF9800),
                ),
                const SizedBox(height: 12),

                // Timeline
                Row(
                  children: [
                    Icon(Icons.timeline, size: 20, color: Color(0xFFFF9800)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'THỜI GIAN LÀM VIỆC',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(startDate)} - ${endDate != null ? dateFormat.format(endDate) : 'Hiện tại'}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Reason (if available)
                if (history.reason != null && history.reason!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    Icons.note_alt,
                    'Lý do',
                    history.reason!,
                    iconColor: Color(0xFFFF9800),
                  ),
                ],
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${history.employeeId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'History ID: ${history.historyId.substring(0, 6)}...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color iconColor = const Color(0xFFFF9800)}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class EmployeeHistoryResponse {
  final String historyId;
  final String employeeId;
  final String? employeeName;
  final String? departmentId;
  final String? departmentName;
  final String? positionId;
  final String? positionName;
  final String startDate;
  final String? endDate;
  final String? reason;
  final String status;

  EmployeeHistoryResponse({
    required this.historyId,
    required this.employeeId,
    this.employeeName,
    this.departmentId,
    this.departmentName,
    this.positionId,
    this.positionName,
    required this.startDate,
    this.endDate,
    this.reason,
    required this.status,
  });

  factory EmployeeHistoryResponse.fromJson(Map<String, dynamic> json) {
    // Xử lý cả 2 trường hợp naming convention
    return EmployeeHistoryResponse(
      historyId: json['historyId'] ?? json['historyID'] ?? 'unknown',
      employeeId: json['employeeId'] ?? json['employedId'] ?? 'unknown',
      employeeName: json['employeeName'] ?? json['employesName'],
      departmentId: json['departmentId'] ?? json['departmentID'],
      departmentName: json['departmentName'],
      positionId: json['positionId'] ?? json['positionID'],
      positionName: json['positionName'] ?? json['position'],
      startDate: json['startDate'] ?? '1970-01-01',
      endDate: json['endDate'],
      reason: json['reason'],
      status: json['status'] ?? 'Inactive',
    );
  }
}