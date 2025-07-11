import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class AddEmployeeScreen extends StatefulWidget {
  final String token;
  final String? employeeId;

  const AddEmployeeScreen({Key? key, required this.token, this.employeeId}) : super(key: key);

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _hireDateController = TextEditingController();

  String? _gender;
  String? _selectedDepartmentId;
  String? _selectedPositionId;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _positions = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchDropdownData();
    if (widget.employeeId != null && widget.employeeId!.isNotEmpty) {
      await _loadEmployeeDetail(widget.employeeId!);
    }
  }

  Future<void> _loadEmployeeDetail(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.employeeUrl}/$employeeId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      // print("DEBUG: employeeId gửi sang AddEmployeeScreen: ${employee.id}");
      print("Employee ID: ${widget.employeeId}");
      print("URL: ${Constants.employeeUrl}/${widget.employeeId}");


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _gender = data['gender'];
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _dateOfBirthController.text = data['dateOfBirth'] ?? '';
          _hireDateController.text = data['hireDate'] ?? '';

          _selectedDepartmentId = _departments.any((dep) => dep['departmentId'].toString() == data['departmentId'].toString())
              ? data['departmentId'].toString()
              : null;

          _selectedPositionId = _positions.any((pos) => pos['positionId'].toString() == data['positionId'].toString())
              ? data['positionId'].toString()
              : null;
        });
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy nhân viên này.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi không xác định khi tải nhân viên.')),
        );
      }
    } catch (e) {
      print('Lỗi khi tải thông tin nhân viên: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final depRes = await http.get(
        Uri.parse(Constants.departmentsUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      final posRes = await http.get(
        Uri.parse(Constants.positionsUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print("Departments body: ${depRes.body}");
      print("Positions body: ${posRes.body}");

      if (depRes.statusCode == 200 && posRes.statusCode == 200) {
        final depJson = jsonDecode(depRes.body);
        final posJson = jsonDecode(posRes.body);

        setState(() {
          _departments = List<Map<String, dynamic>>.from(depJson['result']); // nếu bên departments cũng là 'result'
          _positions = List<Map<String, dynamic>>.from(posJson['result']);
        });
      } else {
        throw Exception('Lỗi khi tải danh sách phòng ban/chức vụ');
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      "fullName": _fullNameController.text.trim(),
      "gender": _gender,
      "dateOfBirth": _dateOfBirthController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "img": "https://example.com/images/default.jpg",
      "departmentId": _selectedDepartmentId,
      "positionId": _selectedPositionId,
      "hireDate": _hireDateController.text.trim(),
    };

    final url = widget.employeeId == null
        ? Uri.parse(Constants.employeeUrl)
        : Uri.parse('${Constants.employeeUrl}/${widget.employeeId}');

    final response = await (widget.employeeId == null
        ? http.post(url, headers: _headers(), body: jsonEncode(body))
        : http.put(url, headers: _headers(), body: jsonEncode(body)));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final msg = widget.employeeId == null
          ? 'Thêm nhân viên thành công'
          : 'Cập nhật nhân viên thành công';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context, true);
    } else {
      String errorMessage = 'Lỗi không xác định';
      if (response.body.isNotEmpty) {
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? errorMessage;
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $errorMessage')));
    }
  }

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${widget.token}',
    'Content-Type': 'application/json',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeId != null ? 'Sửa nhân viên' : 'Thêm nhân viên'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(label: 'Họ tên', controller: _fullNameController),
              _buildDropdown(
                label: 'Giới tính',
                value: _gender,
                items: ['Male', 'Female'].map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _gender = val),
              ),
              _buildTextField(
                  label: 'Số điện thoại',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField(label: 'Địa chỉ', controller: _addressController),
              _buildDateField(label: 'Ngày sinh', controller: _dateOfBirthController),
              _buildDateField(label: 'Ngày bắt đầu', controller: _hireDateController),
              _buildDropdown(
                label: 'Phòng ban',
                value: _selectedDepartmentId != null &&
                    _departments.any((p) => p['departmentId'].toString() == _selectedDepartmentId)
                    ? _selectedDepartmentId
                    : null,
                items: _departments.map((p) => DropdownMenuItem<String>(
                  value: p['departmentId'].toString(),
                  child: Text(p['departmentName'].toString()),
                )).toList(),
                onChanged: (val) => setState(() => _selectedDepartmentId = val),
              ),

              _buildDropdown(
                label: 'Chức vụ',
                value: _selectedPositionId != null &&
                    _positions.any((p) => p['positionId'].toString() == _selectedPositionId)
                    ? _selectedPositionId
                    : null,
                items: _positions.map((p) => DropdownMenuItem<String>(
                  value: p['positionId'].toString(),
                  child: Text(p['positionName'].toString()), // cho chức vụ
                )).toList(),
                onChanged: (val) => setState(() => _selectedPositionId = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Lưu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDate(controller),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Vui lòng chọn $label' : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Vui lòng chọn $label' : null,
      ),
    );
  }
}
