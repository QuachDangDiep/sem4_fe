import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

// ✅ MODEL: Department
class Department {
  final String departmentId;
  final String departmentName;

  Department({required this.departmentId, required this.departmentName});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
    );
  }
}

// ✅ SCREEN: TransferDepartmentScreen
class TransferDepartmentScreen extends StatefulWidget {
  final String token;
  final String employeeId;

  const TransferDepartmentScreen({
    super.key,
    required this.token,
    required this.employeeId,
  });

  @override
  State<TransferDepartmentScreen> createState() => _TransferDepartmentScreenState();
}

class _TransferDepartmentScreenState extends State<TransferDepartmentScreen> {
  List<Department> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  // 🔄 Fetch departments from backend
  Future<void> fetchDepartments() async {
    final response = await http.get(
      Uri.parse(Constants.getActiveDepartments),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List result = data['result'];
      setState(() {
        _departments = result.map((e) => Department.fromJson(e)).toList();
      });
    } else {
      print("❌ Lỗi lấy danh sách phòng ban");
    }
  }

  // 🔁 Transfer department for the employee
  Future<void> transferDepartment() async {
    if (_selectedDepartmentId == null) return;

    setState(() {
      _isLoading = true;
    });

    final response = await http.put(
      Uri.parse(
          '${Constants.baseUrl}/api/employees/${widget.employeeId}/change-department?departmentId=$_selectedDepartmentId'
      ),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Chuyển phòng ban thành công')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Chuyển phòng ban thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuyển phòng ban')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Chọn phòng ban mới',
                border: OutlineInputBorder(),
              ),
              items: _departments
                  .map((d) => DropdownMenuItem<String>(
                value: d.departmentId,
                child: Text(d.departmentName),
              ))
                  .toList(),
              value: _selectedDepartmentId,
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: transferDepartment,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Chuyển phòng ban'),
            ),
          ],
        ),
      ),
    );
  }
}
