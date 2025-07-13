import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

class UpdateEmployeeScreen extends StatefulWidget {
  final String token;
  final String employeeId;
  final Map<String, dynamic> employeeData;

  const UpdateEmployeeScreen({
    Key? key,
    required this.token,
    required this.employeeId,
    required this.employeeData,
  }) : super(key: key);

  @override
  State<UpdateEmployeeScreen> createState() => _UpdateEmployeeScreenState();
}

class _UpdateEmployeeScreenState extends State<UpdateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  String? _base64Image;

  late TextEditingController fullNameController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController departmentIdController;
  late TextEditingController positionIdController;
  late TextEditingController hireDateController;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.employeeData['fullName']);
    genderController = TextEditingController(text: widget.employeeData['gender']);
    dobController = TextEditingController(text: widget.employeeData['dateOfBirth']);
    phoneController = TextEditingController(text: widget.employeeData['phone']);
    addressController = TextEditingController(text: widget.employeeData['address']);
    departmentIdController = TextEditingController(text: widget.employeeData['departmentId']);
    positionIdController = TextEditingController(text: widget.employeeData['positionId']);
    hireDateController = TextEditingController(text: widget.employeeData['hireDate']);
    _base64Image = widget.employeeData['img']; // giữ nguyên ảnh ban đầu
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final rawBytes = await pickedFile.readAsBytes();

      // ✅ Chuyển đổi sang ảnh JPEG
      final decodedImage = img.decodeImage(rawBytes);
      if (decodedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Không thể đọc ảnh')),
        );
        return;
      }

      final jpegBytes = img.encodeJpg(decodedImage, quality: 90); // 90% chất lượng

      setState(() {
        _imageFile = File(pickedFile.path);
        _base64Image = base64Encode(jpegBytes); // ✅ Dùng ảnh JPEG để encode
      });
    }
  }

  Future<void> updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse(Constants.updateEmployeeUrl(widget.employeeId));
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };

    final body = jsonEncode({
      'fullName': fullNameController.text,
      'gender': genderController.text,
      'dateOfBirth': dobController.text,
      'phone': phoneController.text,
      'address': addressController.text,
      'img': _base64Image, // gửi base64
      'departmentId': departmentIdController.text,
      'positionId': positionIdController.text,
      'hireDate': hireDateController.text,
    });

    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Cập nhật thành công')),
      );
      Navigator.pop(context, true);
    } else {
      final json = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Thất bại: ${json['message']}')),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.orange,
            colorScheme: ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Sửa thông tin nhân viên'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_base64Image != null
                              ? MemoryImage(base64Decode(_base64Image!))
                              : null) as ImageProvider<Object>?,
                          child: (_imageFile == null && _base64Image == null)
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          label: const Text('Sửa ảnh', style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  ),
                  _buildTextField('Họ tên', fullNameController),
                  _buildTextField('Giới tính', genderController),
                  _buildDateField('Ngày sinh', dobController),
                  _buildTextField('Số điện thoại', phoneController),
                  _buildTextField('Địa chỉ', addressController),
                  _buildTextField('Mã phòng ban', departmentIdController),
                  _buildTextField('Mã chức vụ', positionIdController),
                  _buildDateField('Ngày nhận việc', hireDateController),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: updateEmployee,
                    icon: const Icon(Icons.save),
                    label: const Text('Cập nhật'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) => value!.isEmpty ? '$label không được bỏ trống' : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(controller),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.orange),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) => value!.isEmpty ? '$label không được bỏ trống' : null,
      ),
    );
  }
}
