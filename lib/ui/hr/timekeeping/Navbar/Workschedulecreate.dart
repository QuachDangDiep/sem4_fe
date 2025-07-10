import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sem4_fe/ui/Hr/Timekeeping/Timekeeping.dart';
import 'package:sem4_fe/Service/Constants.dart';

class WorkScheduleInfo {
  final String scheduleInfoId;
  final String name;
  final String description;
  final String defaultStartTime;
  final String defaultEndTime;
  final String status;

  WorkScheduleInfo({
    required this.scheduleInfoId,
    required this.name,
    required this.description,
    required this.defaultStartTime,
    required this.defaultEndTime,
    required this.status,
  });

  factory WorkScheduleInfo.fromJson(Map<String, dynamic> json) {
    return WorkScheduleInfo(
      scheduleInfoId: json['scheduleInfoId']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      defaultStartTime: json['defaultStartTime'] ?? '',
      defaultEndTime: json['defaultEndTime'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class WorkScheduleInfoCreateScreen extends StatefulWidget {
  final String token;
  final WorkScheduleInfo? existingSchedule;

  const WorkScheduleInfoCreateScreen({super.key, required this.token,  this.existingSchedule,});

  @override
  State<WorkScheduleInfoCreateScreen> createState() => _WorkScheduleInfoCreateScreenState();
}

class _WorkScheduleInfoCreateScreenState extends State<WorkScheduleInfoCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void dispose() {
    // ✅ Đừng quên giải phóng bộ nhớ
    _nameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _nameController.text = schedule.name;
      _descriptionController.text = schedule.description;

      // Parse giờ bắt đầu và kết thúc từ chuỗi "HH:mm:ss"
      final startParts = schedule.defaultStartTime.split(":");
      final endParts = schedule.defaultEndTime.split(":");

      if (startParts.length >= 2) {
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
      }

      if (endParts.length >= 2) {
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }

      _status = schedule.status;
    }
  }

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _status = 'Active';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Chọn giờ';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String _formatTimeForBackend(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm:ss').format(dt); // thêm giây
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    final isEditing = widget.existingSchedule != null;

    final body = jsonEncode({
      "name": _nameController.text.trim(),
      "description": _descriptionController.text.trim(),
      "defaultStartTime": _formatTimeForBackend(_startTime!),
      "defaultEndTime": _formatTimeForBackend(_endTime!),
      "status": _status,
    });

    final url = isEditing
        ? "${Constants.workScheduleInfoUrl}/${widget.existingSchedule!.scheduleInfoId}"
        : Constants.workScheduleInfoUrl;

    print("🔁 Đang gọi API: $url");
    print("📦 Payload: $body");
    print("🔑 Token: ${widget.token}");


    final response = await (isEditing
        ? http.put(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    }, body: body)
        : http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    }, body: body));

    print("📥 Status code: ${response.statusCode}");
    print("📥 Body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Cập nhật thành công')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Cập nhật thất bại: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.existingSchedule != null ? 'Chỉnh sửa ca làm' :'Tạo ca làm mặc định'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Thông tin ca làm",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên ca làm',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value!.isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Giờ làm mặc định", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_formatTime(_startTime)),
                      onPressed: () => _pickTime(true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_filled),
                      label: Text(_formatTime(_endTime)),
                      onPressed: () => _pickTime(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Hoạt động')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Ngưng')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'Active'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: Text(
                    widget.existingSchedule != null ? "Cập nhật" : "Tạo ca làm",
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
