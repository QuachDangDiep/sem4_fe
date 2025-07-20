import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/Attendance.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/histotyqr.dart';

class AttendanceManagementScreen extends StatefulWidget {
  final String token;

  const AttendanceManagementScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  List<dynamic> attendanceList = [];
  List<dynamic> employeeList = [];
  bool isLoading = true;
  bool isLoadingStats = false;
  bool _showStats = true;


  int checkedIn = 0;
  int late = 0;
  int absent = 0;
  int total = 0;
  DateTime? _fromDate;
  DateTime? _toDate;


  String? selectedEmployeeId;
  final Color _primaryColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    fetchEmployeeList();
    fetchAttendance();
    fetchAttendanceStats();
  }

  // ----------------------------- API CALLS -----------------------------
  Future<void> fetchAttendance() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(Constants.activeQrAttendanceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        attendanceList = json.decode(response.body);
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      print('Lỗi tải attendance: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> getUserRoleId() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.rolesUrl),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final roles = jsonDecode(response.body)['result'] ?? [];
        final userRole = roles.firstWhere(
              (r) => r['roleName']?.toString().toLowerCase() == 'user',
          orElse: () => null,
        );
        return userRole?['roleId']?.toString();
      }
    } catch (e) {
      print('Lỗi getUserRoleId: $e');
    }
    return null;
  }

  Future<List<dynamic>> fetchUsers({String? roleId}) async {
    try {
      final uri = Uri.parse(Constants.homeUrl);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final usersRaw = jsonDecode(response.body)['result'] ?? [];
        return usersRaw.where((u) => u['role']?.toString() == roleId).toList();
      }
    } catch (e) {
      print('Lỗi fetchUsers: $e');
    }
    return [];
  }

  Future<void> fetchEmployeeList() async {
    setState(() => isLoading = true);
    try {
      final roleId = await getUserRoleId();
      if (roleId == null) return;

      final users = await fetchUsers(roleId: roleId);
      List<dynamic> employees = [];

      for (var user in users) {
        final empIdRes = await http.get(
          Uri.parse(Constants.employeeIdByUserIdUrl(user['userId'])),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (empIdRes.statusCode != 200 || empIdRes.body.trim().isEmpty) continue;

        final empId = empIdRes.body.trim();
        final detailRes = await http.get(
          Uri.parse(Constants.employeeDetailUrl(empId)),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (detailRes.statusCode == 200) {
          employees.add(jsonDecode(detailRes.body));
        }
      }

      setState(() => employeeList = employees);
    } catch (e) {
      print('Lỗi fetchEmployeeList: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAttendanceStats() async {
    setState(() => isLoadingStats = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Lấy danh sách tất cả employee với role là User
      final roleId = await getUserRoleId();
      if (roleId == null) throw Exception('Không tìm thấy roleId');

      final users = await fetchUsers(roleId: roleId);
      final allEmployeeIds = <String>{};

      for (var user in users) {
        final empIdRes = await http.get(
          Uri.parse(Constants.employeeIdByUserIdUrl(user['userId'])),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (empIdRes.statusCode == 200 && empIdRes.body.trim().isNotEmpty) {
          allEmployeeIds.add(empIdRes.body.trim());
        }
      }

      final totalEmployees = allEmployeeIds.length;

      // 2. Lấy danh sách bản ghi chấm công
      final url = Uri.parse('${Constants.baseUrl}/api/attendances');
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        int present = 0, lateCount = 0;
        final checkedInSet = <String>{};

        for (var item in data) {
          final date = item['attendanceDate'];
          final status = item['status'];
          final empId = item['employee']?['employeeId']?.toString();

          if (empId == null || date == null || status == null) continue;

          final dateFormatted = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
          if (dateFormatted != today) continue;

          if (status == 'Present' || status == 'Late') {
            checkedInSet.add(empId);
            if (status == 'Present') present++;
            if (status == 'Late') lateCount++;
          }
        }

        setState(() {
          total = totalEmployees;
          checkedIn = checkedInSet.length;
          late = lateCount;
          absent = totalEmployees - checkedInSet.length;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu chấm công');
      }
    } catch (e) {
      print('Lỗi fetchAttendanceStats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thống kê: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoadingStats = false);
    }
  }


  // ----------------------------- UI HELPERS -----------------------------
  String formatDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  List<dynamic> getFilteredAttendance() {
    List<dynamic> filtered = (selectedEmployeeId == null || selectedEmployeeId!.isEmpty)
        ? List.from(attendanceList)
        : attendanceList.where((e) => e['employee']?['employeeId'] == selectedEmployeeId).toList();

    if (_fromDate != null) {
      filtered = filtered.where((e) {
        final date = DateTime.tryParse(e['attendanceDate'] ?? '');
        return date != null && date.isAfter(_fromDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (_toDate != null) {
      filtered = filtered.where((e) {
        final date = DateTime.tryParse(e['attendanceDate'] ?? '');
        return date != null && date.isBefore(_toDate!.add(const Duration(days: 1)));
      }).toList();
    }

    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['attendanceDate'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['attendanceDate'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  Widget buildDropdown() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: DropdownButtonFormField<String>(
        value: selectedEmployeeId,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          labelText: 'Chọn nhân viên',
          labelStyle: TextStyle(color: Colors.grey[700]),
          floatingLabelStyle: TextStyle(color: _primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
          ),
        ),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
        style: TextStyle(color: Colors.black87, fontSize: 16),
        items: employeeList.map((emp) {
          final id = emp['employeeId'].toString();
          return DropdownMenuItem(
            value: id,
            child: Text(emp['fullName'] ?? 'Không rõ', style: TextStyle(fontSize: 16)),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() => selectedEmployeeId = value);

          final selectedEmployee = employeeList.firstWhere(
                (e) => e['employeeId'].toString() == value,
            orElse: () => null,
          );

          if (selectedEmployee != null) {
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Xem lịch sử chấm công'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceHistoryScreen(
                                employeeId: value!,
                                employeeName: selectedEmployee['fullName'] ?? '',
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.bar_chart),
                        title: const Text('Xem thống kê chấm công'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceSummaryScreen(
                                token: widget.token,
                                employeeId: value!,
                                employeeName: selectedEmployee['fullName'] ?? 'Không rõ',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fromDate ?? DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.orange, // màu cam chủ đạo
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _fromDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange, width: 1.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fromDate != null ? DateFormat('dd/MM/yyyy').format(_fromDate!) : 'Từ ngày',
                        style: TextStyle(
                          fontSize: 15,
                          color: _fromDate != null ? Colors.black87 : Colors.orange.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _toDate ?? DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.orange,
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _toDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange, width: 1.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _toDate != null ? DateFormat('dd/MM/yyyy').format(_toDate!) : 'Đến ngày',
                        style: TextStyle(
                          fontSize: 15,
                          color: _toDate != null ? Colors.black87 : Colors.orange.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAttendanceList() {
    final list = getFilteredAttendance();

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) return const Center(child: Text('Không có dữ liệu chấm công'));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final emp = item['employee'] ?? {};
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp['fullName'] ?? 'Không rõ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Mã NV: ${emp['employeeId'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildInfoRow(Icons.calendar_today, 'Ngày chấm công:', formatDate(item['attendanceDate'] ?? '')),
                  buildInfoRow(Icons.fingerprint, 'Phương thức:', item['attendanceMethod'] ?? 'N/A'),
                  buildInfoRow(Icons.check_circle, 'Trạng thái:', item['status'] ?? 'N/A'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$label ',
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStatistics() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thống kê hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: Icon(Icons.refresh, color: _primaryColor), onPressed: fetchAttendanceStats),
            ],
          ),
          const SizedBox(height: 12),
          isLoadingStats
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard('Đã chấm công', '$checkedIn', Colors.green),
              _buildStatCard('Đi muộn', '$late', Colors.orange),
              _buildStatCard('Vắng mặt', '$absent', Colors.red),
              _buildStatCard('Tổng số', '$total', _primaryColor),
            ].map((card) {
              return SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 24,
                child: card,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin, color: color, size: 36),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // ----------------------------- MAIN UI -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chấm công'),
        backgroundColor: _primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.visibility_off : Icons.visibility, color: Colors.white),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
            tooltip: _showStats ? 'Ẩn thống kê' : 'Hiện thống kê',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showStats) buildStatistics(),  // chỉ hiển thị nếu _showStats = true
          buildDropdown(),
          buildDateFilter(),
          Expanded(child: buildAttendanceList()),
        ],
      ),
    );
  }
}