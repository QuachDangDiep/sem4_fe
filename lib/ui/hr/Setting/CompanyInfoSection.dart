import 'package:flutter/material.dart';

class CompanyInfoSection extends StatefulWidget {
  @override
  _CompanyInfoSectionState createState() => _CompanyInfoSectionState();
}

class _CompanyInfoSectionState extends State<CompanyInfoSection> {
  final _nameController = TextEditingController(
      text: 'Công ty TNHH Quản lý Nhân sự Việt Nam');
  final _addressController = TextEditingController(
      text:
      'Tầng 15, Tòa nhà Viettel, 285 Cách Mạng Tháng 8,\nPhường 12, Quận 10, TP. Hồ Chí Minh');
  final _phoneController = TextEditingController(text: '028 3822 1155');
  final _emailController =
  TextEditingController(text: 'contact@hrmanagement.vn');

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        // Cho phép cuộn nếu nội dung vượt chiều cao container
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo_company.png',
                      height: 80,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Chọn logo mới
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Thay đổi logo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Các trường nhập liệu
              _buildTextField(controller: _nameController, label: 'Tên công ty'),
              _buildTextField(
                  controller: _addressController, label: 'Địa chỉ', maxLines: 3),
              _buildTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  keyboardType: TextInputType.phone),
              _buildTextField(
                  controller: _emailController,
                  label: 'Email liên hệ',
                  keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final name = _nameController.text;
                  final address = _addressController.text;
                  final phone = _phoneController.text;
                  final email = _emailController.text;

                  print('Lưu thành công: $name, $address, $phone, $email');
                },
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
