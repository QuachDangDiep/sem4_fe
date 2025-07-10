import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Setting/Navbar/DepartmentManagementPage.dart';

class AddDepartmentScreen extends StatefulWidget {
  final String token;
  final Department? department;

  const AddDepartmentScreen({
    Key? key,
    required this.token,
    this.department, // thêm dòng này
  }) : super(key: key);

  @override
  State<AddDepartmentScreen> createState() => _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends State<AddDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _status = 'Active'; // hoặc giá trị mặc định bạn muốn
  bool _isLoading = false;

  Future<void> _submitDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(Constants.departmentsUrl), // 👈 chỉnh URL nếu cần
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'departmentName': _nameController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Thêm phòng ban thành công')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message'] ?? 'Thêm thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> submitDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'departmentName': _nameController.text.trim(),
      'status': _status,
    });

    final url = widget.department == null
        ? Uri.parse(Constants.departmentsUrl)
        : Uri.parse('${Constants.departmentsUrl}/${widget.department!.departmentId}');

    try {
      final response = await (widget.department == null
          ? http.post(url, headers: headers, body: body)
          : http.put(url, headers: headers, body: body));

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.department == null
              ? '✅ Thêm thành công'
              : '✅ Cập nhật thành công')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message'] ?? 'Thao tác thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.department?.departmentName ?? '',
    );
    _status = widget.department?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose(); // đóng controller để tránh memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Thêm phòng ban'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading
              ? null
              : () {
            Navigator.pop(context); // nếu bạn chỉ muốn quay lại
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập thông tin phòng ban',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên phòng ban',
                  prefixIcon: const Icon(Icons.apartment_outlined),
                  filled: true,
                  fillColor: Colors.orange.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên phòng ban';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Đang xử lý...' : 'Lưu',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: _isLoading
                      ? null
                      : (widget.department == null
                      ? _submitDepartment
                      : submitDepartment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
