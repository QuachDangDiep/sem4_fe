import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Đảm bảo đã thêm fl_chart vào pubspec.yaml
import 'package:sem4_fe/ui/hr/Setting/Setting.dart';
import 'package:sem4_fe/ui/hr/Staff/staff.dart';

class HomeHRPage extends StatefulWidget {
  final String username;
  final String token;

  const HomeHRPage({super.key, required this.username, required this.token});

  @override
  State<HomeHRPage> createState() => _HomeHRPageState();
}

class _HomeHRPageState extends State<HomeHRPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StaffScreen(
            username: widget.username,
            token: widget.token,
          ),
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HrSettingsPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Quản lý Nhân sự",
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SearchBox(),
            SizedBox(height: 16),
            HorizontalSummaryCards(),
            SizedBox(height: 16),
            RevenueChart(),
            SizedBox(height: 16),
            AttendanceRatio(),
            SizedBox(height: 16),
            NewEmployeesSection(),
          ],
        ),
      )
          : const Center(
        child: Text('Chức năng đang được phát triển...'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Nhân viên'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'Chấm công'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

// ================= WIDGETS =================

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm nhân viên...',
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class HorizontalSummaryCards extends StatelessWidget {
  const HorizontalSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          SummaryCard(
            title: 'Tổng doanh thu',
            value: '2.5 tỷ VNĐ',
            subtitle: '↑ 1.12% so với tháng trước',
          ),
          SizedBox(width: 12),
          SummaryCard(
            title: 'Tổng nhân viên',
            value: '125',
            subtitle: '5 nhân viên mới',
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title, value, subtitle;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }
}

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Doanh thu theo tuần", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("Tuần này", style: TextStyle(color: Colors.blue)),
          ),
          const SizedBox(height: 12),
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
                      getTitlesWidget: (value, _) {
                        const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                        if (value.toInt() < 0 || value.toInt() >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[value.toInt()]),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final yValue = (i + 1) * 50.0 + (i == 5 ? 100 : 0);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: yValue, color: Colors.blue, width: 12),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceRatio extends StatelessWidget {
  const AttendanceRatio({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Tỷ lệ chấm công hôm nay", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          _ProgressItem(label: "Đúng giờ", value: 0.85, color: Colors.green),
          _ProgressItem(label: "Đi trễ", value: 0.10, color: Colors.orange),
          _ProgressItem(label: "Vắng mặt", value: 0.05, color: Colors.red),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text("${(value * 100).toInt()}%"),
        ],
      ),
    );
  }
}

class NewEmployeesSection extends StatelessWidget {
  const NewEmployeesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Nhân viên mới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 12),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text("Nguyễn Văn A"),
            subtitle: Text("Nhân viên kinh doanh"),
          ),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text("Trần Thị B"),
            subtitle: Text("Nhân viên IT"),
          ),
        ],
      ),
    );
  }
}
