import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';
import 'package:sem4_fe/ui/Hr/Setting/Navbar/Positionpost.dart';

// ⚠️ Cập nhật URL backend theo địa chỉ máy chủ thật của bạn
const String apiUrl = Constants.positionsUrl;

class PositionListScreen extends StatefulWidget {
  final String token;

  const PositionListScreen({Key? key, required this.token}) : super(key: key);

  @override
  _PositionListScreenState createState() => _PositionListScreenState();
}

class _PositionListScreenState extends State<PositionListScreen> {
  late Future<List<Position>> _futurePositions;

  @override
  void initState() {
    super.initState();
    _futurePositions = fetchPositions();
  }

  Future<List<Position>> fetchPositions() async {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['result'];
      return list.map((e) => Position.fromJson(e)).toList();
    } else {
      throw Exception('❌ Lỗi lấy danh sách chức vụ');
    }
  }

  void _confirmDelete(String positionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa chức vụ này?'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(); // đóng dialog
              _handleDelete(positionId);  // gọi hàm xử lý riêng
            },
          ),
        ],
      ),
    );
  }

  void _handleDelete(String positionId) async {
    await Future.delayed(Duration(milliseconds: 100)); // đảm bảo dialog đã đóng
    if (mounted) {
      await _deletePosition(positionId);
    }
  }

  Future<void> _deletePosition(String positionId) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/$positionId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (!mounted) return; // 💡 kiểm tra context còn hợp lệ

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Xóa thành công')),
      );
      setState(() {
        _futurePositions = fetchPositions(); // cập nhật lại danh sách
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Xóa thất bại')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách chức vụ'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm chức vụ',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPositionScreen(token: widget.token),
                  ),
                ).then((_) {
                  // khi màn hình thêm quay lại
                  if (mounted) {
                    setState(() {
                      _futurePositions = fetchPositions(); // reload lại danh sách
                    });
                  }
                });
              }
          ),
        ],
      ),
      body: FutureBuilder<List<Position>>(
        future: _futurePositions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('❌ ${snapshot.error}'));
          }

          final positions = snapshot.data!;
          if (positions.isEmpty) {
            return const Center(child: Text('Không có chức vụ nào'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: positions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pos = positions[index];
              final isActive = pos.status == 'Active';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green[100] : Colors.red[100],
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.work_outline,
                          color: isActive ? Colors.green[700] : Colors.red[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pos.positionName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  color: isActive ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                  style: TextStyle(
                                    color: isActive ? Colors.green[700] : Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Sửa',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddPositionScreen(
                                    token: widget.token,
                                    position: pos,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  setState(() {
                                    _futurePositions = fetchPositions();
                                  });
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Xóa',
                            onPressed: () => _confirmDelete(pos.positionId),
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

class Position {
  final String positionId;
  final String positionName;
  final String status;

  Position({
    required this.positionId,
    required this.positionName,
    required this.status,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      positionId: json['positionId'] ?? '',
      positionName: json['positionName'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
