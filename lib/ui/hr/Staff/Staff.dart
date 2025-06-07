import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/hr/home/HomeHr.dart'; // Đổi đường dẫn này theo đúng vị trí file HomeHR của bạn

class StaffScreen extends StatelessWidget {
  final String username;
  final String token;

  const StaffScreen({super.key, required this.token, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nhân sự'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    '3',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.jpg'), // đổi ảnh nếu cần
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhân viên...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Lọc'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                )
              ],
            ),
          ),
          // Danh sách nhân viên
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                StaffCard(
                  name: 'Nguyễn Văn An',
                  id: 'NV001',
                  role: 'Nhân viên bán hàng',
                  status: 'Đang làm việc',
                  shift: 'Ca Sáng',
                  image: 'assets/avatar.jpg',
                ),
                StaffCard(
                  name: 'Trần Thị Bình',
                  id: 'NV002',
                  role: 'Kế toán',
                  status: 'Nghỉ phép',
                  shift: 'Ca Sáng',
                  image: 'assets/avatar.jpg',
                ),
                StaffCard(
                  name: 'Lê Văn Cường',
                  id: 'NV003',
                  role: 'Kỹ thuật viên',
                  status: 'Đang làm việc',
                  shift: 'Ca Tối',
                  image: 'assets/avatar.jpg',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Nhân viên đang được chọn
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            // Điều hướng về HomeHR
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeHRPage(
                  username: username,
                  token: token,
                ),
              ),
            );
          }
          // Nếu bạn muốn xử lý các tab khác, thêm ở đây
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Nhân viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Chấm công',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final String name;
  final String id;
  final String role;
  final String status;
  final String shift;
  final String image;

  const StaffCard({
    super.key,
    required this.name,
    required this.id,
    required this.role,
    required this.status,
    required this.shift,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == 'Đang làm việc'
        ? Colors.green.shade100
        : Colors.orange.shade100;
    Color statusTextColor = status == 'Đang làm việc'
        ? Colors.green.shade800
        : Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: AssetImage(image),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã NV: $id'),
            Text(role),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusTextColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shift,
                style: TextStyle(
                  color: Colors.deepPurple.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
