import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Import các màn hình phụ
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

  // Màu sắc theo yêu cầu đã tinh chỉnh nhẹ cho hài hòa hơn
  final List<Color> customColors = [
    const Color(0xFFFFE0B2), // nền nhạt hơn, tone cam nhẹ nhàng
    const Color(0xFFFFA726), // cam vừa phải
    const Color(0xFFFB8C00), // cam đậm vừa
    const Color(0xFFEF6C00), // cam đậm mạnh hơn cho điểm nhấn
  ];

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
      backgroundColor: Colors.white, // đổi thành màu trắng đặc
      appBar: AppBar(
        backgroundColor: customColors[1],
        elevation: 2,
        title: const Text(
          "Quản lý Nhân sự",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: customColors[3]),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchBox(),
            const SizedBox(height: 20),
            HorizontalSummaryCards(customColors: customColors),
            const SizedBox(height: 24),
            RevenueChart(customColors: customColors),
            const SizedBox(height: 24),
            AttendanceRatio(customColors: customColors),
            const SizedBox(height: 24),
            const NewEmployeesSection(),
          ],
        ),
      )
          : Center(
        child: Text(
          'Chức năng đang được phát triển...',
          style: TextStyle(
              color: customColors[2],
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: customColors[3],
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Nhân viên'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint_outlined), label: 'Chấm công'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

// =================== Các Widget con ===================

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm nhân viên...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
        ),
      ),
    );
  }
}

class HorizontalSummaryCards extends StatelessWidget {
  final List<Color> customColors;

  const HorizontalSummaryCards({super.key, required this.customColors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          SummaryCard(
            title: 'Tổng doanh thu',
            value: '2.5 tỷ VNĐ',
            subtitle: '↑ 1.12% so với tháng trước',
            color: customColors[1],
          ),
          const SizedBox(width: 16),
          SummaryCard(
            title: 'Tổng nhân viên',
            value: '125',
            subtitle: '5 nhân viên mới',
            color: customColors[2],
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title, value, subtitle;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: color.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: color,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}

class RevenueChart extends StatelessWidget {
  final List<Color> customColors;

  const RevenueChart({super.key, required this.customColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: customColors[0].withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: customColors[3].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Doanh thu theo tuần",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: customColors[3],
                  fontSize: 18)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text("Tuần này",
                style: TextStyle(
                  color: customColors[1],
                  fontWeight: FontWeight.w600,
                )),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
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
                        if (value.toInt() < 0 || value.toInt() >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(days[value.toInt()],
                            style: TextStyle(
                                color: customColors[3],
                                fontWeight: FontWeight.bold));
                      },
                      reservedSize: 36,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final revenueValues = [5, 7, 4, 9, 8, 5, 6];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: revenueValues[index].toDouble(),
                        color: customColors[3],
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      )
                    ],
                  );
                }),
                gridData: FlGridData(show: false),
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceRatio extends StatelessWidget {
  final List<Color> customColors;

  const AttendanceRatio({super.key, required this.customColors});

  @override
  Widget build(BuildContext context) {
    final data = {
      'Có mặt': 82,
      'Nghỉ phép': 8,
      'Nghỉ không phép': 10,
    };
    final total = data.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: customColors[0].withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: customColors[3].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tỷ lệ đi làm",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: customColors[3],
                  fontSize: 18)),
          const SizedBox(height: 16),
          Column(
            children: data.entries.map((entry) {
              final percentage = (entry.value / total) * 100;
              final color = entry.key == 'Có mặt'
                  ? Colors.green
                  : (entry.key == 'Nghỉ phép' ? Colors.orange : Colors.red);
              return AttendanceBar(
                label: entry.key,
                percentage: percentage,
                color: color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class AttendanceBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const AttendanceBar(
      {super.key,
        required this.label,
        required this.percentage,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width * 0.6 * (percentage / 100),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text("${percentage.toStringAsFixed(1)}%",
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class NewEmployeesSection extends StatelessWidget {
  const NewEmployeesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newEmployees = [
      {
        'name': 'Nguyễn Văn A',
        'position': 'Nhân viên kinh doanh',
        'avatar': null,
      },
      {
        'name': 'Trần Thị B',
        'position': 'Nhân viên kỹ thuật',
        'avatar': null,
      },
      {
        'name': 'Lê Văn C',
        'position': 'Nhân viên Marketing',
        'avatar': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhân viên mới',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: newEmployees.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            final employee = newEmployees[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange.shade300,
                child: Text(
                  employee['name']![0],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                ),
              ),
              title: Text(employee['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(employee['position']!),
              trailing: IconButton(
                icon: const Icon(Icons.message_outlined, color: Colors.orange),
                onPressed: () {
                  // TODO: Mở chat hoặc gửi tin nhắn
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
