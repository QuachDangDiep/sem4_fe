import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class AddEmployeeScreen extends StatefulWidget {
  final String token;
  final String? employeeId;
  final String? userId;
  final String? username;
  final String? positionName;
  final String? departmentName;
  final String? gender;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? hireDate;
  final String? image;

  const AddEmployeeScreen({
    Key? key,
    required this.token,
    this.employeeId,
    this.userId,
    this.username,
    this.positionName,
    this.departmentName,
    this.gender,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.hireDate,
    this.image,
  }) : super(key: key);

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _fetchDropdownData();
      if (widget.employeeId != null && widget.employeeId!.isNotEmpty) {
        await _loadEmployeeDetail(widget.employeeId!);
      } else {
        _fullNameController.text = widget.username ?? '';
        _phoneController.text = widget.phone ?? '';
        _addressController.text = widget.address ?? '';
        _dateOfBirthController.text = widget.dateOfBirth ?? '';
        _hireDateController.text = widget.hireDate ?? '';
        _gender = widget.gender;
        if (widget.departmentName != null && _departments.isNotEmpty) {
          final department = _departments.firstWhere(
                (dep) => dep['departmentName'] == widget.departmentName,
            orElse: () => {},
          );
          _selectedDepartmentId = department.isNotEmpty ? department['departmentId'].toString() : null;
        }
        if (widget.positionName != null && _positions.isNotEmpty) {
          final position = _positions.firstWhere(
                (pos) => pos['positionName'] == widget.positionName,
            orElse: () => {},
          );
          _selectedPositionId = position.isNotEmpty ? position['positionId'].toString() : null;
        }
      }
    } catch (e) {
      debugPrint('Error in _initializeData: $e');
    } finally {
      setState(() => _isLoading = false);
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
      debugPrint("Employee ID: ${widget.employeeId}");
      debugPrint("URL: ${Constants.employeeUrl}/$employeeId");
      debugPrint("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fullNameController.text = data['fullName'] ?? widget.username ?? '';
          _gender = data['gender'] ?? widget.gender;
          _phoneController.text = data['phone'] ?? widget.phone ?? '';
          _addressController.text = data['address'] ?? widget.address ?? '';
          _dateOfBirthController.text = data['dateOfBirth'] ?? widget.dateOfBirth ?? '';
          _hireDateController.text = data['hireDate'] ?? widget.hireDate ?? '';

          _selectedDepartmentId = _departments.isNotEmpty && data['departmentId'] != null
              ? _departments.firstWhere(
                (dep) => dep['departmentId'].toString() == data['departmentId'].toString(),
            orElse: () => {},
          )['departmentId']?.toString()
              : null;
          _selectedPositionId = _positions.isNotEmpty && data['positionId'] != null
              ? _positions.firstWhere(
                (pos) => pos['positionId'].toString() == data['positionId'].toString(),
            orElse: () => {},
          )['positionId']?.toString()
              : null;

          if (_selectedDepartmentId == null && widget.departmentName != null && _departments.isNotEmpty) {
            final department = _departments.firstWhere(
                  (dep) => dep['departmentName'] == widget.departmentName,
              orElse: () => {},
            );
            _selectedDepartmentId = department.isNotEmpty ? department['departmentId'].toString() : null;
          }
          if (_selectedPositionId == null && widget.positionName != null && _positions.isNotEmpty) {
            final position = _positions.firstWhere(
                  (pos) => pos['positionName'] == widget.positionName,
              orElse: () => {},
            );
            _selectedPositionId = position.isNotEmpty ? position['positionId'].toString() : null;
          }
        });
      } else {
        setState(() {
          _fullNameController.text = widget.username ?? '';
          _phoneController.text = widget.phone ?? '';
          _addressController.text = widget.address ?? '';
          _dateOfBirthController.text = widget.dateOfBirth ?? '';
          _hireDateController.text = widget.hireDate ?? '';
          _gender = widget.gender;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải chi tiết nhân viên: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin nhân viên: $e');
      setState(() {
        _fullNameController.text = widget.username ?? '';
        _phoneController.text = widget.phone ?? '';
        _addressController.text = widget.address ?? '';
        _dateOfBirthController.text = widget.dateOfBirth ?? '';
        _hireDateController.text = widget.hireDate ?? '';
        _gender = widget.gender;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin nhân viên: $e')),
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

      debugPrint("Departments response: ${depRes.statusCode} - ${depRes.body}");
      debugPrint("Positions response: ${posRes.statusCode} - ${posRes.body}");

      if (depRes.statusCode == 200 && posRes.statusCode == 200) {
        final depJson = jsonDecode(depRes.body);
        final posJson = jsonDecode(posRes.body);

        setState(() {
          _departments = List<Map<String, dynamic>>.from(depJson['result'] ?? []);
          _positions = List<Map<String, dynamic>>.from(posJson['result'] ?? []);
          debugPrint("Loaded departments: $_departments");
          debugPrint("Loaded positions: $_positions");
        });
      } else {
        throw Exception('Lỗi khi tải danh sách phòng ban/chức vụ: Departments=${depRes.statusCode}, Positions=${posRes.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch dropdown error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách phòng ban/chức vụ: $e')),
      );
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: Colors.orange,
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: Colors.orange.shade50,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final body = {
      "fullName": _fullNameController.text.trim(),
      "gender": _gender,
      "dateOfBirth": _dateOfBirthController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "img": widget.image ?? "https://example.com/images/default.jpg",
      "departmentId": _selectedDepartmentId,
      "positionId": _selectedPositionId,
      "hireDate": _hireDateController.text.trim(),
      if (widget.userId != null) "userId": widget.userId,
    };

    final url = widget.employeeId == null
        ? Uri.parse(Constants.employeeUrl)
        : Uri.parse('${Constants.employeeUrl}/${widget.employeeId}');

    try {
      final response = await (widget.employeeId == null
          ? http.post(url, headers: _headers(), body: jsonEncode(body))
          : http.put(url, headers: _headers(), body: jsonEncode(body)));

      debugPrint("Submit response: ${response.statusCode} - ${response.body}");

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
    } catch (e) {
      debugPrint('Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isLoading = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(label: 'Địa chỉ', controller: _addressController),
              _buildDateField(label: 'Ngày sinh', controller: _dateOfBirthController),
              _buildDateField(label: 'Ngày bắt đầu', controller: _hireDateController),
              _buildDropdown(
                label: 'Phòng ban',
                value: _selectedDepartmentId,
                items: _departments.map((p) => DropdownMenuItem<String>(
                  value: p['departmentId'].toString(),
                  child: Text(p['departmentName'].toString()),
                )).toList(),
                onChanged: (val) => setState(() => _selectedDepartmentId = val),
              ),
              _buildDropdown(
                label: 'Chức vụ',
                value: _selectedPositionId,
                items: _positions.map((p) => DropdownMenuItem<String>(
                  value: p['positionId'].toString(),
                  child: Text(p['positionName'].toString()),
                )).toList(),
                onChanged: (val) => setState(() => _selectedPositionId = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Đang lưu...' : 'Lưu'),
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
    FocusNode? focusNode,
    TextInputType? keyboardType,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Focus(
        onFocusChange: (_) => setState(() {}),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: isFocused ? Colors.orange.shade700 : Colors.grey.shade600,
            ),
            floatingLabelStyle: TextStyle(
              color: Colors.orange.shade700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập $label' : null,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    final focusNode = FocusNode();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Focus(
        onFocusChange: (_) => setState(() {}),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          onTap: () => _pickDate(controller),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Icon(
              Icons.calendar_today,
              color: focusNode.hasFocus ? Colors.orange.shade700 : Colors.grey.shade700,
            ),
            labelStyle: TextStyle(
              color: focusNode.hasFocus ? Colors.orange.shade700 : Colors.grey.shade600,
            ),
            floatingLabelStyle: TextStyle(
              color: Colors.orange.shade700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          validator: (value) => value == null || value.isEmpty ? 'Vui lòng chọn $label' : null,
        ),
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
        value: items.isNotEmpty ? value : null,
        items: items,
        onChanged: items.isNotEmpty ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.orange.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) => value == null || value.isEmpty ? 'Vui lòng chọn $label' : null,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }
}