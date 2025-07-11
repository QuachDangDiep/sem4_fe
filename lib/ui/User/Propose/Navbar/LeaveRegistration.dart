import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';

class LeaveRegistrationPage extends StatefulWidget {
  final String token;

  const LeaveRegistrationPage({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _LeaveRegistrationPageState createState() => _LeaveRegistrationPageState();
}

class _LeaveRegistrationPageState extends State<LeaveRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _leaveType;
  String _reason = '';
  bool _isLoading = false;
  String? _employeeId;
  bool _fetchingEmployeeId = true;
  final TextEditingController _reasonController = TextEditingController();

  final Map<String, String> _leaveTypes = {
    'SickLeave': 'Nghỉ ốm',
    'AnnualLeave': 'Nghỉ phép',
    'UnpaidLeave': 'Nghỉ không lương',
    'Other': 'Nghỉ khác',
  };
  @override
  void initState() {
    super.initState();
    _fetchEmployeeId();
    _leaveType = _leaveTypes.keys.first;
  }

  bool isValidJwtFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3;
  }

  Future<void> _fetchEmployeeId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Token không tồn tại');

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) throw Exception('Không tìm thấy userId trong token');

      final employeeResponse = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (employeeResponse.statusCode != 200) {
        throw Exception('Không lấy được employeeId');
      }

      final id = employeeResponse.body.trim();
      if (id.isEmpty) throw Exception('employeeId rỗng');

      setState(() {
        _employeeId = id;
        _fetchingEmployeeId = false;
      });
    } catch (e) {
      setState(() {
        _employeeId = null;
        _fetchingEmployeeId = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi lấy employeeId: $e')),
        );
      }
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

    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy employeeId')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Token không tồn tại');

      final leaveResponse = await http.post(
        Uri.parse(Constants.leaveRegistrationUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "employeeId": _employeeId,
          "leaveStartDate": DateFormat('yyyy-MM-dd').format(_selectedStartDate!),
          "leaveEndDate": DateFormat('yyyy-MM-dd').format(_selectedEndDate!),
          "leaveType": _leaveType,
          "reason": _reason,
        }),
      );

      if (!mounted) return;

      final leaveData = json.decode(leaveResponse.body);
      if (leaveResponse.statusCode == 200 || leaveResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(leaveData['message'] ?? 'Đăng ký nghỉ phép thành công')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(leaveData['message'] ?? 'Đăng ký nghỉ phép thất bại');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi gửi đơn nghỉ phép: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // màu cam cho AppBar và ngày được chọn
              onPrimary: Colors.white, // màu chữ trắng trên AppBar
              onSurface: Colors.black, // màu chữ ngày thường
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.orange), // nút "OK", "HỦY"
            ),
          ),
          child: child!,
        );
      },
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fetchingEmployeeId) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký nghỉ phép',style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),),
          centerTitle: true,
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_employeeId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký nghỉ phép'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không thể lấy thông tin nhân viên'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchEmployeeId,
                child: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký nghỉ phép',style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loại nghỉ
              const Text('Loại nghỉ:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _leaveType != null && _leaveTypes.containsKey(_leaveType!)
                    ? _leaveType
                    : null,
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
                validator: (value) => value == null ? 'Vui lòng chọn loại nghỉ' : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 20),

              // Ngày bắt đầu
              const Text('Ngày bắt đầu:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _selectStartDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedStartDate != null
                            ? DateFormat('dd/MM/yyyy')
                            .format(_selectedStartDate!)
                            : 'Chọn ngày bắt đầu',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ngày kết thúc
              const Text('Ngày kết thúc:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: _selectedStartDate == null
                    ? null
                    : () => _selectEndDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedEndDate != null
                            ? DateFormat('dd/MM/yyyy')
                            .format(_selectedEndDate!)
                            : 'Chọn ngày kết thúc',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lý do
              const Text('Lý do:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2),
                  ),
                  hintText: 'Nhập lý do nghỉ...',
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

              // Nút gửi
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLeaveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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
    );
  }
}