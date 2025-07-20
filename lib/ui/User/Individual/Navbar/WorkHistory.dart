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
  String? _userId;
  String? _employeeId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchHistory();
  }

  Future<void> _loadUserIdAndFetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = widget.token; // Use widget.token instead of SharedPreferences
      debugPrint('Auth token: $token');
      if (token == null) throw Exception('Token không tồn tại');

      // Kiểm tra token có hợp lệ không
      debugPrint('Checking token validity');
      if (JwtDecoder.isExpired(token)) {
        debugPrint('Token is expired');
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      }

      // Lấy userId từ token
      final decoded = JwtDecoder.decode(token);
      debugPrint('Decoded JWT: $decoded');
      _userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (_userId == null) throw Exception('Không tìm thấy userId trong token');
      debugPrint('Extracted userId: $_userId');

      // Lấy employeeId từ API
      final empRes = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(_userId!)),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('Employee ID API Response: ${empRes.statusCode} - ${empRes.body}');

      if (empRes.statusCode != 200) {
        throw Exception('Không lấy được employeeId: ${empRes.statusCode} - ${empRes.body}');
      }

      // Kiểm tra nếu body rỗng hoặc không hợp lệ
      if (empRes.body.trim().isEmpty) {
        throw Exception('Không tìm thấy employeeId trong phản hồi API');
      }

      // Xử lý cả trường hợp body là chuỗi hoặc JSON
      try {
        final employeeData = jsonDecode(empRes.body);
        _employeeId = employeeData['employeeId']?.toString() ?? employeeData['id']?.toString();
        if (_employeeId == null) throw Exception('Không tìm thấy employeeId trong JSON');
      } catch (e) {
        _employeeId = empRes.body.trim();
      }
      debugPrint('Extracted employeeId: $_employeeId');

      await _fetchWorkHistory();
    } catch (e, stackTrace) {
      debugPrint('Error in _loadUserIdAndFetchHistory: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Lỗi khi tải lịch sử làm việc: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWorkHistory() async {
    try {
      // Kiểm tra lại token trước khi gọi API
      debugPrint('Re-checking token validity before fetching work history');
      if (JwtDecoder.isExpired(widget.token)) {
        debugPrint('Token is expired in _fetchWorkHistory');
        setState(() {
          _workHistoryList = [];
          _isLoading = false;
          _errorMessage = 'Token đã hết hạn. Vui lòng đăng nhập lại.';
        });
        return;
      }

      // Kiểm tra employeeId trước khi gọi API
      if (_employeeId == null || _employeeId!.isEmpty) {
        throw Exception('employeeId không hợp lệ');
      }

      // Sử dụng endpoint tổng quát để lấy lịch sử làm việc
      final url = Constants.employeeHistoriesUrl;
      debugPrint('Requesting work history for employeeId: $_employeeId at URL: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      debugPrint('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Parsed API response data: $data');
        if (data['success'] == true || data['code'] == 200) {
          final List<dynamic> historyData = data['result'] ?? [];

          debugPrint('Raw history data: ${historyData.toString()}');

          setState(() {
            _workHistoryList = historyData
                .map((json) => EmployeeHistoryResponse.fromJson(json))
                .where((history) => history.employeeId == _employeeId) // Lọc client-side theo employeeId
                .toList();
            _isLoading = false;
            debugPrint('Work history count after filtering: ${_workHistoryList.length}');
          });
        } else {
          throw Exception(data['message'] ?? 'Lỗi không xác định từ API');
        }
      } else if (response.statusCode == 404 || response.statusCode == 401) {
        setState(() {
          _workHistoryList = [];
          _isLoading = false;
          debugPrint('No work history or unauthorized access for employeeId: $_employeeId');
        });
      } else {
        throw Exception('Lỗi server: ${response.statusCode} - ${response.body}');
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
        title: const Text(
          'Lịch sử làm việc',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[700],
        elevation: 4,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[700]!, Colors.orange[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : _workHistoryList.isEmpty
            ? Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Text(
              'Không có lịch sử làm việc',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _workHistoryList.length,
          itemBuilder: (context, index) {
            final history = _workHistoryList[index];
            return _buildHistoryCard(history);
          },
        ),
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

    return GestureDetector(
      onTap: () {
        // Optional: Add tap feedback or navigation if needed
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
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
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: history.status == 'Active'
                      ? [Colors.green[100]!, Colors.green[50]!]
                      : [Colors.red[100]!, Colors.red[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: history.status == 'Active' ? Colors.green[600] : Colors.red[600],
                    radius: 6,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      history.employeeName ?? 'Không có tên',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    history.status == 'Active' ? 'ĐANG LÀM' : 'ĐÃ NGHỈ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: history.status == 'Active' ? Colors.green[800] : Colors.red[800],
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
                  // Department
                  _buildDetailItem(
                    Icons.apartment,
                    'Phòng ban',
                    history.departmentName ?? 'Chưa cập nhật',
                    iconColor: Colors.orange[700]!,
                  ),
                  const SizedBox(height: 16),
                  // Position
                  _buildDetailItem(
                    Icons.badge,
                    'Chức vụ',
                    history.positionName ?? 'Chưa cập nhật',
                    iconColor: Colors.orange[700]!,
                  ),
                  const SizedBox(height: 16),
                  // Timeline
                  _buildDetailItem(
                    Icons.timeline,
                    'Thời gian làm việc',
                    '${dateFormat.format(startDate)} - ${endDate != null ? dateFormat.format(endDate) : 'Hiện tại'}',
                    iconColor: Colors.orange[700]!,
                  ),
                  // Reason (if available)
                  if (history.reason != null && history.reason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      Icons.note_alt,
                      'Lý do',
                      history.reason!,
                      iconColor: Colors.orange[700]!,
                    ),
                  ],
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'History ID: ${history.historyId.substring(0, 6)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {required Color iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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