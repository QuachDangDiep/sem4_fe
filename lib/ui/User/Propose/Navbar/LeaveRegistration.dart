import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRegistrationPage extends StatefulWidget {
  final String employeeId;
  final String token;

  const LeaveRegistrationPage({
    Key? key,
    required this.employeeId,
    required this.token,
  }) : super(key: key);

  @override
  _LeaveRegistrationPageState createState() => _LeaveRegistrationPageState();
}

class _LeaveRegistrationPageState extends State<LeaveRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _leaveType = 'AnnualLeave';
  String _reason = '';
  bool _isLoading = false;
  final TextEditingController _reasonController = TextEditingController();

  final Map<String, String> _leaveTypes = {
    'AnnualLeave': 'Nghỉ phép',
    'SickLeave': 'Nghỉ ốm',
    'UnpaidLeave': 'Nghỉ không lương',
    'Other': 'Nghỉ khác'
  };

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
          _selectedEndDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_selectedStartDate == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate!,
      firstDate: _selectedStartDate!,
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(Constants.leaveRegistrationUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "employeeId": widget.employeeId,
          "leaveStartDate": DateFormat('yyyy-MM-dd').format(_selectedStartDate!),
          "leaveEndDate": DateFormat('yyyy-MM-dd').format(_selectedEndDate!),
          "leaveType": _leaveType,
          "reason": _reason,
        }),
      );
      final data = json.decode(response.body);
      final fetchedEmployeeId = data['employeeId'];

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('employee_id', fetchedEmployeeId);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Đăng ký nghỉ phép thành công')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(responseData['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _selectedStartDate = null;
      _selectedEndDate = null;
      _leaveType = 'AnnualLeave';
      _reason = '';
      _reasonController.clear();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF57C00);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng ký nghỉ phép',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetForm,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại nghỉ:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _leaveType,
                    items: _leaveTypes.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _leaveType = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    iconEnabledColor: primaryColor,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Ngày bắt đầu:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedStartDate != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!)
                                : 'Chọn ngày bắt đầu',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const Icon(Icons.calendar_today, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Ngày kết thúc:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  InkWell(
                    onTap: _selectedStartDate == null ? null : () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedEndDate != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                : 'Chọn ngày kết thúc',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const Icon(Icons.calendar_today, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Lý do:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      hintText: 'Nhập lý do nghỉ...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập lý do nghỉ';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _reason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitLeaveRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Gửi đơn',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
