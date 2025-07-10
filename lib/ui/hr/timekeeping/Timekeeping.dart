import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Timekeeping/Navbar/Workschedulecreate.dart';

class WorkScheduleInfoListScreen extends StatefulWidget {
  final String token;
  final WorkScheduleInfo? existingSchedule;
  final String username;

  const WorkScheduleInfoListScreen({
    Key? key,
    required this.token,
    this.existingSchedule,
    required this.username, // 👈 Thêm dòng này
  }) : super(key: key);

  @override
  State<WorkScheduleInfoListScreen> createState() => _WorkScheduleInfoListScreenState();
}

class _WorkScheduleInfoListScreenState extends State<WorkScheduleInfoListScreen> {
  late Future<List<WorkScheduleInfo>> _futureList;

  @override
  void initState() {
    super.initState();
    _futureList = fetchWorkScheduleInfos();
  }

  Future<List<WorkScheduleInfo>> fetchWorkScheduleInfos() async {
    final url = Uri.parse(Constants.workScheduleInfoUrl);
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['result'];
      return data.map((item) => WorkScheduleInfo.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load data: ${response.body}');
    }
  }

  Future<void> _deleteSchedule(String scheduleInfoId) async {
    try {
      final response = await http.delete(
        Uri.parse("${Constants.workScheduleInfoUrl}/$scheduleInfoId"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Xóa ca làm thành công")),
        );
        setState(() => _futureList = fetchWorkScheduleInfos());
      } else {
        throw Exception("Không thể xóa: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi xóa: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true, // đảm bảo căn giữa tiêu đề
        title: const Text(
          'Quản lý ca làm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkScheduleInfoCreateScreen(
                      token: widget.token,
                    ),
                  ),
                );
                if (result == true) {
                  setState(() => _futureList = fetchWorkScheduleInfos()); // ✅ Đúng
                }
              }
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<WorkScheduleInfo>>(
        future: _futureList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final schedules = snapshot.data!;
          if (schedules.isEmpty) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final s = schedules[index];
              final isActive = s.status == 'Active';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: Colors.orange.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.orange.shade50,
                            child: const Icon(Icons.schedule, color: Colors.deepOrange, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.login, size: 16, color: Colors.orange),
                                    const SizedBox(width: 6),
                                    Text('Giờ vào: ${s.defaultStartTime}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.logout, size: 16, color: Colors.orange),
                                    const SizedBox(width: 6),
                                    Text('Giờ tan: ${s.defaultEndTime}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.description, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        s.description,
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkScheduleInfoCreateScreen(
                                    token: widget.token,
                                    existingSchedule: s,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => _futureList = fetchWorkScheduleInfos());
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Xác nhận xóa"),
                                  content: Text("Bạn có chắc muốn xóa ca làm '${s.name}' không?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _deleteSchedule(s.scheduleInfoId);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
