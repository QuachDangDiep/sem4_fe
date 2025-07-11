import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sem4_fe/Service/Constants.dart';

class UpdatePersonalInfoScreen extends StatefulWidget {
  final Map<String, dynamic> employeeData;

  const UpdatePersonalInfoScreen({
    Key? key,
    required this.employeeData,
  }) : super(key: key);

  @override
  State<UpdatePersonalInfoScreen> createState() => _UpdatePersonalInfoScreenState();
}

class _UpdatePersonalInfoScreenState extends State<UpdatePersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  File? _selectedImage;
  String? _base64Image;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final data = widget.employeeData;

    _dobController = TextEditingController(text: _formatDate(data['dateOfBirth']));
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _addressController = TextEditingController(text: data['address'] ?? '');
    _base64Image = data['img']; // Load ảnh gốc từ backend nếu có
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 9, 21),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _parseDate(String input) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(input);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return input;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final base64Str = base64Encode(bytes);
    final ext = pickedFile.path.split('.').last;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _base64Image = "data:image/$ext;base64,$base64Str";
    });
  }

  Future<void> _updateEmployeeInfo() async {
    final token = widget.employeeData['token'] ?? '';
    final employeeId = widget.employeeData['employeeId'] ?? '';

    final dob = _dobController.text.trim();
    final parsedDate = _parseDate(dob);

    final body = {
      "fullName": widget.employeeData['fullName'] ?? "",
      "gender": widget.employeeData['gender'] ?? "Other",
      "dateOfBirth": parsedDate,
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "img": widget.employeeData['img'] ?? "",
      "departmentId": widget.employeeData['departmentId'] ?? null,
      "positionId": widget.employeeData['positionId'] ?? null,
    };


    try {
      final response = await http.put(
        Uri.parse(Constants.employeeDetailUrl(employeeId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi gửi yêu cầu cập nhật')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (_base64Image != null && _base64Image!.startsWith("data:image"))
        ? MemoryImage(base64Decode(_base64Image!.split(',').last)) as ImageProvider
        : const AssetImage('assets/images/avatar_placeholder.png');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật thông tin'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: avatarImage,
                      backgroundColor: Colors.grey[300],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form fields
              Align(alignment: Alignment.centerLeft, child: _buildLabel('Ngày sinh', true)),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dobController,
                    decoration: _inputDecorationWithIcon(Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Align(alignment: Alignment.centerLeft, child: _buildLabel('Số điện thoại')),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 16),

              Align(alignment: Alignment.centerLeft, child: _buildLabel('Địa chỉ hiện tại')),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _updateEmployeeInfo();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Xác nhận'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, [bool isRequired = false]) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        children: isRequired
            ? [const TextSpan(text: ' (*)', style: TextStyle(color: Colors.red))]
            : [],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  InputDecoration _inputDecorationWithIcon(IconData icon) {
    return InputDecoration(
      suffixIcon: Icon(icon, color: Colors.orange),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
