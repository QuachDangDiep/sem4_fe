import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/ui/Hr/Setting/Navbar/PositionManagementPage.dart';
import 'package:sem4_fe/Service/Constants.dart';

class AddPositionScreen extends StatefulWidget {
  final String token;
  final Position? position;// bạn cần truyền vào token khi gọi màn hình này

  const AddPositionScreen({
    Key? key,
    required this.token,
    this.position, // 👈 Đánh dấu là không bắt buộc
  }) : super(key: key);

  @override
  State<AddPositionScreen> createState() => _AddPositionScreenState();
}

class _AddPositionScreenState extends State<AddPositionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _status = 'Active';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 👇 Nếu là chế độ sửa thì gán dữ liệu cũ vào form
    if (widget.position != null) {
      _nameController.text = widget.position!.positionName;
      _status = widget.position!.status;
    }
  }

  Future<void> _submitPosition() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = widget.position == null
        ? Uri.parse(Constants.positionsUrl)
        : Uri.parse('${Constants.positionsUrl}/${widget.position!.positionId}');

    final method = widget.position == null ? 'POST' : 'PUT';
    final body = jsonEncode({
      'positionName': _nameController.text.trim(),
      'status': _status,
    });

    final response = await (method == 'POST'
        ? http.post(uri, headers: _headers(), body: body)
        : http.put(uri, headers: _headers(), body: body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.position == null ? '✅ Thêm thành công' : '✅ Cập nhật thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Thao tác thất bại')),
      );
    }
  }

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${widget.token}',
    'Content-Type': 'application/json',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.position == null ? 'Thêm chức vụ' : 'Cập nhật chức vụ'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 3,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên chức vụ',
                        prefixIcon: const Icon(Icons.work_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên chức vụ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isLoading ? "Đang xử lý..." : "Lưu chức vụ",
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : _submitPosition,
                      ),
                    )
                  ],
                ),
              ),
            ),
            )
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF6F6F6),
    );
  }
}
