import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Leaverquest/AttendanceAppeal.dart';
import 'package:sem4_fe/ui/Hr/Staff/Narbar/StaffDetailScreen.dart';

class LeaveResponse {
  final String requestId;
  final String employeeId;
  final String employeeName;
  final DateTime leaveStartDate;
  final DateTime leaveEndDate;
  final String leaveType;
  final String status;
  final String activeStatus;

  LeaveResponse({
    required this.requestId,
    required this.employeeId,
    required this.employeeName,
    required this.leaveStartDate,
    required this.leaveEndDate,
    required this.leaveType,
    required this.status,
    required this.activeStatus,
  });

  factory LeaveResponse.fromJson(Map<String, dynamic> json, {String? employeeName}) {
    return LeaveResponse(
      requestId: json['leaveId']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: employeeName ?? json['employeeName']?.toString() ?? 'Unknown',
      leaveStartDate: DateTime.tryParse(json['leaveStartDate'].toString()) ?? DateTime.now(),
      leaveEndDate: DateTime.tryParse(json['leaveEndDate'].toString()) ?? DateTime.now(),
      leaveType: json['leaveType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      activeStatus: json['activeStatus']?.toString() ?? 'Active',
    );
  }
}

class LeaveRequestPage extends StatefulWidget {
  final String username;
  final String token;

  const LeaveRequestPage({super.key, required this.username, required this.token});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final colors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFFFA726),
    const Color(0xFFFB8C00),
    const Color(0xFFEF6C00),
  ];
  int _selectedIndex = 3; // Highlight "Đơn xin nghỉ"

  Future<String> fetchEmployeeName(String employeeId) async {
    try {
      print('Fetching employee name for employeeId: $employeeId');
      final response = await http.get(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      print('Employee name API response status: ${response.statusCode}');
      print('Employee name API response body: ${response.body}');
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

  Future<List<LeaveResponse>> fetchLeaveRequests() async {
    try {
      print('Fetching leave requests from: http://10.0.2.2:8080/api/leaves');
      final response = await http.get(
        Uri.parse(Constants.leaveRegistrationUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Leave requests API response status: ${response.statusCode}');
      print('Leave requests API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final leaveList = jsonData['data'] ?? jsonData['result'] ?? jsonData['leaves'] ?? [];
        if (leaveList is List) {
          final leaveRequests = <LeaveResponse>[];
          for (var item in leaveList) {
            String? employeeName;
            if (item['employeeName'] == null) {
              employeeName = await fetchEmployeeName(item['employeeId']?.toString() ?? '');
            }
            leaveRequests.add(LeaveResponse.fromJson(item, employeeName: employeeName));
          }
          return leaveRequests..sort((a, b) => b.leaveStartDate.compareTo(a.leaveStartDate));
        } else {
          throw Exception('Dữ liệu không đúng định dạng danh sách: ${jsonData.runtimeType}, content: $jsonData');
        }
      } else {
        throw Exception('Lỗi khi tải dữ liệu đơn xin nghỉ: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching leave requests: $e');
      throw Exception('Lỗi khi tải dữ liệu đơn xin nghỉ: $e');
    }
  }

  Future<void> updateLeaveRequestStatus(String requestId, String status) async {
    try {
      print('Updating leave request $requestId to status: $status');
      final response = await http.put(
        Uri.parse(Constants.leaveDetailUrl(requestId)),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));
      print('PUT URL: ${Constants.leaveDetailUrl(requestId)}');
      print('Update leave request API response status: ${response.statusCode}');
      print('Update leave request API response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái đơn xin nghỉ thành công')),
        );
        setState(() {}); // Refresh the list
      } else {
        throw Exception('Lỗi khi cập nhật trạng thái: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating leave request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: colors[1],
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Quản lý đơn xin nghỉ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_late), // biểu tượng giải trình
            tooltip: 'Giải trình chấm công',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceAppealScreen(token: widget.token),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveResponse>>(
        future: fetchLeaveRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Leave requests fetch error: ${snapshot.error}');
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: TextStyle(color: colors[2], fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Chưa có đơn xin nghỉ nào',
                style: TextStyle(color: colors[2], fontSize: 16),
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    try {
                      final response = await http.get(
                        Uri.parse('${Constants.baseUrl}/api/employees/${request.employeeId}'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                      );

                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        print("Response body: $data"); // <- THÊM DÒNG NÀY
                        final user = data; // <- SỬA Ở ĐÂY

                        if (user == null) {
                          throw Exception("Không tìm thấy dữ liệu nhân viên trong phản hồi API.");
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffDetailScreen(
                              token: widget.token,
                              employeeId: request.employeeId,
                              fullName: user['fullName'] ?? '',
                              status: user['status'] ?? '',
                              image: user['image'] ?? '',
                              positionName: user['positionName'] ?? '',
                              departmentName: user['departmentName'] ?? '',
                              gender: user['gender'] ?? '',
                              phone: user['phone'] ?? '',
                              address: user['address'] ?? '',
                              dateOfBirth: user['dateOfBirth'] ?? '',
                              hireDate: user['hireDate'] ?? '',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi API nhân viên: ${response.statusCode}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi tải thông tin nhân viên: $e')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.orange, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.employeeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.badge, color: Colors.deepPurple, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Mã NV: ${request.employeeId}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                            children: [
                              const Icon(Icons.category, color: Colors.teal, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Loại nghỉ: ${request.leaveType}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ]
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Bắt đầu: ${DateFormat('dd/MM/yyyy').format(request.leaveStartDate)}",
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Kết thúc: ${DateFormat('dd/MM/yyyy').format(request.leaveEndDate)}",
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: request.status == 'Approved'
                                ? Colors.green.shade100
                                : request.status == 'Rejected'
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request.status,
                            style: TextStyle(
                              color: request.status == 'Approved'
                                  ? Colors.green
                                  : request.status == 'Rejected'
                                  ? Colors.red
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (request.status == 'Pending')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => updateLeaveRequestStatus(request.requestId, 'Approved'),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text('Duyệt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => updateLeaveRequestStatus(request.requestId, 'Rejected'),
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  label: const Text('Từ chối'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
