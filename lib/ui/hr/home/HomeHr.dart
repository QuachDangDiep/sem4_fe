import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/ui/hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/hr/Staff/staff.dart';

class UserResponse {
  final String id, username, email, role, status;
  final String? shift, image;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    this.shift,
    this.image,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['userId']?.toString() ?? 'Unknown',
    username: json['username'] ?? 'Không xác định',
    email: json['email'] ?? 'Không có email',
    role: json['role'] ?? '',
    status: json['status'] == 'Active' ? 'Đang làm việc' : (json['status'] ?? 'Không xác định'),
    shift: json['shift'],
    image: json['image'] ?? 'assets/avatar.jpg',
  );
}

class HomeHRPage extends StatefulWidget {
  final String username, token;

  const HomeHRPage({super.key, required this.username, required this.token});

  @override
  State<HomeHRPage> createState() => _HomeHRPageState();
}

class _HomeHRPageState extends State<HomeHRPage> {
  int _selectedIndex = 0;
  final colors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFFFA726),
    const Color(0xFFFB8C00),
    const Color(0xFFEF6C00),
  ];

  Future<String?> getUserRoleId() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/roles'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final roles = jsonDecode(response.body)['result'] ?? [];
        return roles.firstWhere((role) => role['roleName'] == 'User', orElse: () => null)?['roleId'];
      }
    } catch (e) {
      print('Error fetching roles: $e');
    }
    return null;
  }

  Future<List<UserResponse>> fetchUsers({String? status}) async {
    final roleId = await getUserRoleId();
    if (roleId == null) throw Exception('User role not found');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/users${status != null ? '?status=$status' : ''}'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['result'] ?? [])
            .map<UserResponse>((json) => UserResponse.fromJson(json))
            .where((user) => user.role == roleId)
            .toList();
      }
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<int> fetchTotalEmployees() async {
    final users = await fetchUsers();
    return users.length;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffScreen(username: widget.username, token: widget.token)),
        );
        break;
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chức năng ${index == 2 ? "Chấm công" : "Báo cáo"} đang được phát triển')),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HrSettingsPage(username: widget.username, token: widget.token)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: colors[1],
        elevation: 2,
        title: const Text('Quản lý Nhân sự', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: colors[3])),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<int>(
              future: fetchTotalEmployees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Lỗi: ${snapshot.error}', style: TextStyle(color: colors[2]));
                } else {
                  final totalEmployees = snapshot.data ?? 0;
                  return HorizontalSummaryCards(
                    colors: colors,
                    totalEmployees: totalEmployees,
                    username: widget.username,
                    token: widget.token,
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            RevenueChart(colors: colors),
            const SizedBox(height: 24),
            AttendanceRatio(colors: colors),
            const SizedBox(height: 24),
            NewEmployeesSection(colors: colors),
          ],
        ),
      )
          : Center(child: Text('Chức năng đang được phát triển...', style: TextStyle(color: colors[2], fontSize: 16))),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: colors[3],
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Nhân viên'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint_outlined), label: 'Chấm công'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

class HorizontalSummaryCards extends StatelessWidget {
  final List<Color> colors;
  final int totalEmployees;
  final String username;
  final String token;

  const HorizontalSummaryCards({
    super.key,
    required this.colors,
    required this.totalEmployees,
    required this.username,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(width: 16), // Maintain spacing
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffScreen(username: username, token: token),
                ),
              );
            },
            child: SummaryCard(
              title: 'Tổng nhân viên',
              value: totalEmployees.toString(),
              subtitle: '$totalEmployees nhân viên hiện tại',
              color: colors[2],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title, value, subtitle;
  final Color color;

  const SummaryCard({super.key, required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: color)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

class RevenueChart extends StatelessWidget {
  final List<Color> colors;
  const RevenueChart({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(colors[0]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doanh thu theo tuần', style: TextStyle(fontWeight: FontWeight.bold, color: colors[3], fontSize: 16)),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: Text('Tuần này', style: TextStyle(color: colors[1], fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text(
                        ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][value.toInt()],
                        style: TextStyle(color: colors[3], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: [5, 7, 4, 9, 8, 5, 6][i].toDouble(), color: colors[3], width: 20, borderRadius: BorderRadius.circular(6))])),
                gridData: FlGridData(show: false),
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.3),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 6))],
  );
}

class AttendanceRatio extends StatelessWidget {
  final List<Color> colors;
  const AttendanceRatio({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final data = {'Có mặt': 82, 'Nghỉ phép': 8, 'Nghỉ không phép': 10};
    final total = data.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: RevenueChart(colors: colors)._boxDecoration(colors[0]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tỷ lệ đi làm', style: TextStyle(fontWeight: FontWeight.bold, color: colors[3], fontSize: 16)),
          const SizedBox(height: 12),
          ...data.entries.map((e) => AttendanceBar(
            label: e.key,
            percentage: (e.value / total) * 100,
            color: e.key == 'Có mặt' ? Colors.green : (e.key == 'Nghỉ phép' ? Colors.orange : Colors.red),
          )),
        ],
      ),
    );
  }
}

class AttendanceBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const AttendanceBar({super.key, required this.label, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(height: 18, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                Container(height: 18, width: MediaQuery.of(context).size.width * 0.6 * (percentage / 100), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class NewEmployeesSection extends StatelessWidget {
  final List<Color> colors;
  const NewEmployeesSection({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeHRPageState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nhân viên mới', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: colors[3])),
        const SizedBox(height: 12),
        FutureBuilder<List<UserResponse>>(
          future: homeState?.fetchUsers(status: 'Active'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}', style: TextStyle(color: colors[2])));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Không có nhân viên mới', style: TextStyle(color: colors[2])));
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.take(3).length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final employee = snapshot.data![index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: colors[1],
                    backgroundImage: employee.image != null && employee.image!.startsWith('http') ? NetworkImage(employee.image!) : const AssetImage('assets/avatar.jpg'),
                    child: employee.image == null ? Text(employee.username.isNotEmpty ? employee.username[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)) : null,
                  ),
                  title: Text(employee.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(employee.role.isNotEmpty ? employee.role : 'Nhân viên'),
                  trailing: IconButton(icon: Icon(Icons.message_outlined, color: colors[3]), onPressed: () {}),
                );
              },
            );
          },
        ),
      ],
    );
  }
}