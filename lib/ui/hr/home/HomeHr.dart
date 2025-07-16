import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sem4_fe/ui/Hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/Hr/Staff/staff.dart';
import 'package:sem4_fe/ui/Hr/Timekeeping/Timekeeping.dart';
import 'package:sem4_fe/ui/Hr/Leaverquest/Leaverequestpase.dart';
import 'package:sem4_fe/ui/User/QR/Facecame.dart';
import 'package:sem4_fe/ui/User/QR/Qrscanner.dart';

class HomeHRPage extends StatefulWidget {
  final String username;
  final String token;

  const HomeHRPage({super.key, required this.username, required this.token,});

  @override
  State<HomeHRPage> createState() => _HomeHRPageState();
}

class _HomeHRPageState extends State<HomeHRPage> {
  int _selectedIndex = 0;
  final Color _primaryColor = Colors.orange;
  final Color _secondaryColor = Colors.deepOrange;
  final Color _accentColor = Colors.orangeAccent;
  int checkedIn = 0;
  int late = 0;
  int absent = 0;
  int total = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceStats(); // <- thêm dòng này
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> fetchAttendanceStats() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/attendances');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      print('Tổng số bản ghi: ${data.length}');
      for (int i = 0; i < data.length; i++) {
        print('Bản ghi $i: ${json.encode(data[i])}');
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      print('Ngày hôm nay: $today');

      int presentCount = 0;
      int lateCount = 0;
      int absentCount = 0;
      Set<String> employeeIds = {}; // Để đếm nhân viên duy nhất

      for (var attendance in data) {
        final status = attendance['status'];
        final employeeId = attendance['employee']['employeeId'];

        employeeIds.add(employeeId);

        if (status == 'Present') presentCount++;
        else if (status == 'Late') lateCount++;
        else if (status == 'Absent') absentCount++;
      }

      setState(() {
        checkedIn = presentCount;
        late = lateCount;
        absent = absentCount;
        total = employeeIds.length;
        isLoadingStats = false;
      });
    } else {
      print('Lỗi lấy dữ liệu attendance: ${response.statusCode}');
      setState(() => isLoadingStats = false);
    }
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
                      fontSize: 16, fontWeight: FontWeight.w500, color: color),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.4)),
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
    );
  }

  void _navigateToFaceRecognition(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceAttendanceScreen()),
    );
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
              const CircleAvatar(
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
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: Colors.white70),
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
                    fontSize: 15, fontWeight: FontWeight.w600, color: color),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Thống kê hôm nay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        isLoadingStats
            ? const Center(child: CircularProgressIndicator())
            : GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Đã chấm công', '$checkedIn', 'người',
                Icons.check_circle_outline_rounded, Colors.green),
            _buildStatCard('Đi muộn', '$late', 'người',
                Icons.access_time_rounded, Colors.orange),
            _buildStatCard('Vắng mặt', '$absent', 'người',
                Icons.person_off_rounded, Colors.red),
            _buildStatCard('Tổng số', '$total', 'người',
                Icons.people_alt_rounded, _primaryColor),
          ],
        ),
      ],
    );
  }


  Widget _buildStatCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
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
          _buildBottomNavItem(Icons.dashboard_rounded, 'quản lý'),
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