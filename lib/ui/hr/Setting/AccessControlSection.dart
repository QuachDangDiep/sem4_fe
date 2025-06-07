import 'package:flutter/material.dart';

class AccessControlSection extends StatefulWidget {
  @override
  _AccessControlSectionState createState() => _AccessControlSectionState();
}

class _AccessControlSectionState extends State<AccessControlSection> {
  bool salaryInfo = true;
  bool employeeEvaluation = true;
  bool personalInfo = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text('Phân quyền người dùng'),
                subtitle: Text('Quản lý quyền truy cập cho từng người dùng'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Điều hướng sang màn phân quyền người dùng
                },
              ),
              ListTile(
                title: Text('Nhóm quyền'),
                subtitle: Text('Tạo và quản lý các nhóm quyền'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Điều hướng sang màn nhóm quyền
                },
              ),
              ListTile(
                title: Text('Cấp quyền'),
                subtitle: Text('Phân quyền cho các chức năng hệ thống'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Điều hướng sang màn cấp quyền
                },
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quyền truy cập dữ liệu nhạy cảm',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SwitchListTile(
                title: Text('Thông tin lương'),
                value: salaryInfo,
                onChanged: (val) {
                  setState(() {
                    salaryInfo = val;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Đánh giá nhân viên'),
                value: employeeEvaluation,
                onChanged: (val) {
                  setState(() {
                    employeeEvaluation = val;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Thông tin cá nhân'),
                value: personalInfo,
                onChanged: (val) {
                  setState(() {
                    personalInfo = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
