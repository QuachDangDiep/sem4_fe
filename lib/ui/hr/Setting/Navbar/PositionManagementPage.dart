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
              // 👉 Thực hiện hành động chuyển trang tại đây
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPositionScreen(token: widget.token), // truyền token nếu cần
                ),
              );
            },
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final pos = positions[index];
              final isActive = pos.status == 'Active';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green[100] : Colors.red[100],
                    child: Icon(Icons.work_outline, color: isActive ? Colors.green : Colors.red),
                  ),
                  title: Text(pos.positionName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                    style: TextStyle(color: isActive ? Colors.green : Colors.red),
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
