import 'package:flutter/material.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> emp;

  const EmployeeDetailScreen({Key? key, required this.emp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final infoStyle = const TextStyle(fontSize: 15);
    final labelStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 15);

    final statusText = emp['status']?.toString().toLowerCase() ?? '';
    final isActive = statusText == 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nhân viên'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: (emp['avatar'] != null && emp['avatar'].toString().startsWith('http'))
                    ? NetworkImage(emp['avatar'])
                    : const AssetImage('assets/avatar.jpg') as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 16),
              Text(
                emp['fullName'] ?? 'Chưa có tên',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  emp['status'] ?? 'Chưa rõ trạng thái',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.2),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.badge, "Mã nhân viên", emp['employeeId'], labelStyle, infoStyle),
              _buildInfoRow(Icons.work, "Chức vụ", emp['positionName'], labelStyle, infoStyle),
              _buildInfoRow(Icons.apartment, "Phòng ban", emp['departmentName'], labelStyle, infoStyle),
              _buildInfoRow(Icons.person, "Giới tính", emp['gender'], labelStyle, infoStyle),
              _buildInfoRow(Icons.phone, "Số điện thoại", emp['phone'], labelStyle, infoStyle),
              _buildInfoRow(Icons.home, "Địa chỉ", emp['address'], labelStyle, infoStyle),
              _buildInfoRow(Icons.cake, "Ngày sinh", emp['dateOfBirth'], labelStyle, infoStyle),
              _buildInfoRow(Icons.event, "Ngày vào làm", emp['hireDate'], labelStyle, infoStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      dynamic value,
      TextStyle labelStyle,
      TextStyle infoStyle,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label: ',
                style: labelStyle.copyWith(color: Colors.black87),
                children: [
                  TextSpan(
                    text: value?.toString() ?? 'N/A',
                    style: infoStyle.copyWith(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
