import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:table_calendar/table_calendar.dart';

class OvertimeTrackingPage extends StatefulWidget {
  final String token;
  const OvertimeTrackingPage({Key? key, required this.token}) : super(key: key);

  @override
  State<OvertimeTrackingPage> createState() => _OvertimeTrackingPageState();
}

class _OvertimeTrackingPageState extends State<OvertimeTrackingPage> {
  List<dynamic> _otList = [];
  String? _employeeId;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  String _selectedFilter = 'Tất cả'; // ['Tất cả', 'Active', 'Inactive']

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final decoded = JwtDecoder.decode(widget.token);
      final userId = decoded['userId'];

      if (userId == null) return;

      final res = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        _employeeId = res.body.trim();
        await _fetchOT();
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy employeeId: $e");
    }
  }

  Future<void> _fetchOT() async {
    if (_employeeId == null || _fromDate == null || _toDate == null) return;

    setState(() => _isLoading = true);
    List<dynamic> resultAll = [];

    List<String> statusesToFetch =
    _selectedFilter == 'Tất cả' ? ['Active', 'Inactive'] : [_selectedFilter];

    for (String status in statusesToFetch) {
      String url = Constants.overtimeWorkSchedulesByStatusUrl(
        employeeId: _employeeId!,
        status: status,
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate!),
      );

      print("===> Fetching OT with URL: $url");

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${widget.token}',
      });

      print("===> Status ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result is List) {
          resultAll.addAll(result);
        }
      }
    }

    setState(() {
      _otList = resultAll;
      _isLoading = false;
    });

    print("===> Total OT records: ${_otList.length}");

    if (resultAll.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có ca OT nào')),
      );
    }
  }


  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // màu nút, viền
              onPrimary: Colors.white, // chữ trên nút
              onSurface: Colors.black, // chữ ngày
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange, // nút cancel/save
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchOT();
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _otList.where((item) {
      final itemDate = DateTime.parse(item['workDay']);
      return itemDate.year == day.year &&
          itemDate.month == day.month &&
          itemDate.day == day.day;
    }).toList();
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(":");
    return "${parts[0]}:${parts[1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi ca OT'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trạng thái
            Row(
              children: [
                const Text(
                  "Trạng thái:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFilter = val;
                          });
                          _fetchOT();
                        }
                      },
                      items: ['Tất cả', 'Active', 'Inactive'].map((status) {
                        Color color;
                        if (status == 'Tất cả') {
                          color = Colors.black;
                        } else if (status == 'Active') {
                          color = Colors.green;
                        } else {
                          color = Colors.red;
                        }

                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nút chọn khoảng ngày
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _fromDate == null || _toDate == null
                      ? 'Chọn khoảng ngày'
                      : '${DateFormat('dd/MM/yyyy').format(_fromDate!)} - ${DateFormat('dd/MM/yyyy').format(_toDate!)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Lịch + danh sách
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime(2023),
                    lastDay: DateTime(2026),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    eventLoader: _getEventsForDay,
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.map<Widget>((event) {
                            final status = (event as Map<String, dynamic>)['status'];
                            Color color;
                            if (status == 'Active') {
                              color = Colors.green;
                            } else if (status == 'Inactive') {
                              color = Colors.red;
                            } else {
                              color = Colors.grey;
                            }
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Danh sách OT
                  Expanded(
                    child: _otList.isEmpty
                        ? const Center(
                      child: Text(
                        'Không có ca OT nào',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                        : ListView.builder(
                      itemCount: _otList.length,
                      itemBuilder: (context, index) {
                        final ot = _otList[index];
                        final date = ot['workDay'] ?? '';
                        final status = ot['status'] ?? '';
                        final start = _formatTime(ot['scheduleStartTime']);
                        final end = _formatTime(ot['scheduleEndTime']);
                        final isActive = status == 'Active';

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              isActive ? Icons.check_circle : Icons.cancel,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(text: '$date - '),
                                  TextSpan(
                                    text: status,
                                    style: TextStyle(
                                      color: status == 'Active'
                                          ? Colors.green
                                          : status == 'Inactive'
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              'Từ $start đến $end',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
