import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/Hr/Staff/staff.dart';
import 'package:sem4_fe/ui/User/Notification/Notification.dart';
import 'package:sem4_fe/ui/Hr/Timekeeping/Timekeeping.dart';
import 'package:sem4_fe/ui/Hr/Leaverquest/Leaverequestpase.dart';
import 'package:sem4_fe/ui/User/QR/Facecame.dart';
import 'package:sem4_fe/ui/User/QR/Qrscanner.dart';

class HomeHRPage extends StatefulWidget {
  final String username;
  final String token;

  const HomeHRPage({super.key, required this.username, required this.token});

  @override
  State<HomeHRPage> createState() => _HomeHRPageState();
}

class _HomeHRPageState extends State<HomeHRPage> {
  int _selectedIndex = 0;
  final Color _primaryColor = Colors.orange;
  final Color _secondaryColor = Colors.deepOrange;
  int checkedIn = 0;
  int late = 0;
  int absent = 0;
  int total = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceStats();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
          isLoadingStats = false;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu chấm công');
      }
    } catch (e) {
      print('Lỗi fetchAttendanceStats: $e');
      setState(() => isLoadingStats = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thống kê: $e'), backgroundColor: Colors.red),
      );
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

  void _showCheckInOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn phương thức chấm công',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              _buildCheckInOption(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Quét QR Code',
                onTap: () => _navigateToQRScan(context),
                color: _primaryColor,
              ),
              const SizedBox(height: 12),
              _buildCheckInOption(
                icon: Icons.face_retouching_natural_rounded,
                label: 'Nhận diện khuôn mặt',
                onTap: () => _navigateToFaceRecognition(context),
                color: _secondaryColor,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckInOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: color.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.05), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQRScan(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(token: widget.token),
      ),
    ).then((_) => fetchAttendanceStats()); // Làm mới sau khi quét QR
  }

  void _navigateToFaceRecognition(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceAttendanceScreen()),
    ).then((_) => fetchAttendanceStats()); // Làm mới sau khi nhận diện khuôn mặt
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _selectedIndex == 0
          ? AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tổng quan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage(token: widget.token)),
                );
              }

          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      )
          : null,
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () => _showCheckInOptions(context),
        backgroundColor: _primaryColor,
        elevation: 4,
        child: const Icon(Icons.fingerprint_rounded, size: 28),
      )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex != 0) {
      return IndexedStack(
        index: _selectedIndex,
        children: [
          Container(),
          StaffScreen(username: widget.username, token: widget.token),
          WorkScheduleInfoListScreen(username: widget.username, token: widget.token),
          LeaveRequestPage(username: widget.username, token: widget.token),
          HrSettingsPage(username: widget.username, token: widget.token),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildAttendanceOptions(),
          const SizedBox(height: 24),
          _buildStatisticsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_outline_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${widget.username}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chúc bạn một ngày làm việc hiệu quả',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Hôm nay, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Chấm công nhanh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickOption(
                icon: Icons.qr_code_scanner_rounded,
                label: 'QR Code',
                description: 'Quét mã QR để chấm công',
                onTap: () => _navigateToQRScan(context),
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickOption(
                icon: Icons.face_retouching_natural_rounded,
                label: 'Khuôn mặt',
                description: 'Nhận diện khuôn mặt',
                onTap: () => _navigateToFaceRecognition(context),
                color: _secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickOption({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thống kê hôm nay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: _primaryColor, size: 24),
                onPressed: fetchAttendanceStats,
                tooltip: 'Làm mới thống kê',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        isLoadingStats
            ? Center(child: CircularProgressIndicator(color: _primaryColor))
            : (checkedIn == 0 && late == 0 && absent == 0 && total == 0)
            ? Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Center(
            child: Text(
              'Không có dữ liệu chấm công cho hôm nay',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        )
            : GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              'Đã chấm công',
              '$checkedIn',
              'người',
              Icons.check_circle_outline_rounded,
              Colors.green,
            ),
            _buildStatCard(
              'Đi muộn',
              '$late',
              'người',
              Icons.access_time_rounded,
              Colors.orange,
            ),
            _buildStatCard(
              'Vắng mặt',
              '$absent',
              'người',
              Icons.person_off_rounded,
              Colors.red,
            ),
            _buildStatCard(
              'Tổng số',
              '$total',
              'người',
              Icons.people_alt_rounded,
              _primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                unit,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: [
          _buildBottomNavItem(Icons.dashboard_rounded, 'Tổng quan'),
          _buildBottomNavItem(Icons.people_alt_rounded, 'Nhân viên'),
          _buildBottomNavItem(Icons.schedule_rounded, 'Ca làm'),
          _buildBottomNavItem(Icons.note_alt_rounded, 'Quản lý đơn'),
          _buildBottomNavItem(Icons.admin_panel_settings, 'Quản lý') // Sửa nhãn và icon
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      label: label,
    );
  }
}