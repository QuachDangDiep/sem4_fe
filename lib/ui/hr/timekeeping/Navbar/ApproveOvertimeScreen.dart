import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class ApproveOvertimeScreen extends StatefulWidget {
  final String token;

  const ApproveOvertimeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ApproveOvertimeScreen> createState() => _ApproveOvertimeScreenState();
}

class _ApproveOvertimeScreenState extends State<ApproveOvertimeScreen> {
  List<dynamic> schedules = [];
  bool isLoading = true;
  String selectedStatus = 'Inactive';

  @override
  void initState() {
    super.initState();
    fetchPendingOT();
  }

  Future<void> fetchPendingOT() async {
    final url = Uri.parse('${Constants.baseUrl}/api/work-schedules');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data == null || data['result'] == null || data['result'] is! List) {
        setState(() {
          schedules = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗Không có dữ liệu hoặc dữ liệu không hợp lệ')),
        );
        return;
      }

      final List<dynamic> list = data['result'];

      setState(() {
        schedules = list.where((e) {
          final matchType = e['scheduleInfoName'] == 'OT';
          final matchStatus = selectedStatus == 'All' || e['status'] == selectedStatus;
          return matchType && matchStatus;
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi khi tải dữ liệu: ${response.statusCode}')),
      );
    }
  }

  Future<void> approveOT(dynamic rawId) async {
    print('>>> Hàm approveOT được gọi với rawId = $rawId');
    String id = rawId.toString(); // ép kiểu đúng

    final url = Uri.parse('${Constants.baseUrl}/api/work-schedules/approve-ot/$id');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('>>> approveOT gọi với id = $id (${id.runtimeType})');
      for (var item in schedules) {
        print(' - item id = ${item['scheduleId']} (${item['scheduleId'].runtimeType})');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã duyệt ca làm thêm giờ.')),
      );

      setState(() {
        schedules.removeWhere((item) => item['scheduleId'].toString() == id);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Không thể duyệt. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt ca làm thêm giờ'),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.deepOrange.withOpacity(0.3),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.7), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trạng thái:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          items: ['All', 'Inactive', 'Active'].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status == 'All'
                                    ? 'Tất cả'
                                    : status == 'Inactive'
                                    ? 'Chờ duyệt'
                                    : 'Đã duyệt',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                                isLoading = true;
                              });
                              fetchPendingOT();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: schedules.isEmpty
                ? const Center(
              child: Text(
                'Không có ca chờ duyệt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final item = schedules[index];
                return buildScheduleItem(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Di chuyển hàm này ra ngoài build() nhưng vẫn trong class
  Widget buildScheduleItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['employeeName'] ?? 'Không rõ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Ngày làm việc: ${item['workDay'] ?? ''}',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Ca: ${item['startTime']} - ${item['endTime']}',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: item['status'] == 'Active'
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Đã duyệt',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            )
                : ElevatedButton.icon(
              onPressed: () {
                print('>>> Đã nhấn duyệt với id: ${item['scheduleId']}');
                approveOT(item['scheduleId']);
              },
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Duyệt',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
