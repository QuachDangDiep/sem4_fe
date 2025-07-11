import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/User/Individual/Navbar/WorkHistory.dart';

class StaffDetailScreen extends StatelessWidget {
  final String employeeId;
  final String fullName;
  final String status;
  final String image;
  final String? positionName;
  final String? departmentName;
  final String? gender;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? hireDate;
  final String token;

  const StaffDetailScreen({
    Key? key,
    required this.employeeId,
    required this.fullName,
    required this.status,
    required this.image,
    required this.token,
    this.positionName,
    this.departmentName,
    this.gender,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.hireDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Đang làm việc' ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Chi tiết nhân viên', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange.shade600,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: image.startsWith('http')
                    ? NetworkImage(image)
                    : const AssetImage('assets/avatar.jpg') as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // Text(
            //   positionName != null && positionName!.isNotEmpty ? positionName! : '---',
            //   style: const TextStyle(fontSize: 16, color: Colors.grey),
            // ),
            // const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoTile(label: 'Mã nhân viên', value: employeeId, icon: Icons.badge),
                    InfoTile(label: 'Trạng thái', value: status, icon: Icons.circle, iconColor: statusColor),
                    InfoTile(label: 'Chức vụ', value: positionName ?? '---', icon: Icons.work_outline),
                    InfoTile(label: 'Phòng ban', value: departmentName ?? '---', icon: Icons.account_tree_outlined),
                    InfoTile(label: 'Giới tính', value: gender ?? '---', icon: Icons.wc),
                    InfoTile(label: 'SĐT', value: phone ?? '---', icon: Icons.phone),
                    InfoTile(label: 'Địa chỉ', value: address ?? '---', icon: Icons.location_on_outlined),
                    InfoTile(label: 'Ngày sinh', value: dateOfBirth ?? '---', icon: Icons.cake_outlined),
                    InfoTile(label: 'Ngày vào làm', value: hireDate ?? '---', icon: Icons.calendar_today_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkHistoryScreen(token: token),
                  ),
                );
              },
              child: Card(
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: const Text('Xem lịch sử làm việc'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const InfoTile({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.orange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}