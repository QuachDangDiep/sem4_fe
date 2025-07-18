import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String sentBy;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.sentBy,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['sentAt']),
      sentBy: json['sentBy'],
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationPage extends StatefulWidget {
  final String token;
  const NotificationPage({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> dataAllNotification = [];
  bool showOnlyUnread = false;
  String searchText = "";
  int currentPage = 0;
  final int pageSize = 10;
  bool isLoadingMore = false;
  bool hasMore = true;

  late String userId;
  late String userRole;

  @override
  void initState() {
    super.initState();
    final decoded = JwtDecoder.decode(widget.token);
    userId = decoded['userId'];
    userRole = decoded['role'];
    getNotifications(reset: true);
  }

  Future<void> getNotifications({bool reset = false}) async {
    if (reset) {
      setState(() {
        currentPage = 0;
        dataAllNotification.clear();
        hasMore = true;
      });
    }

    if (!hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    final url = "${Constants.baseUrl}/api/notify/received?userId=$userId&role=$userRole&page=$currentPage&size=$pageSize";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<AppNotification> newList =
      jsonList.map((e) => AppNotification.fromJson(e)).toList();

      setState(() {
        dataAllNotification.addAll(newList);
        isLoadingMore = false;
        hasMore = newList.length == pageSize;
        currentPage++;
      });
    } else {
      print("API ERROR: ${response.statusCode}");
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> callMarkAsRead(String id) async {
    final response = await http.post(
      Uri.parse("${Constants.baseUrl}/api/notify/mark-read"),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userId': userId, 'notificationId': id}),
    );
    if (response.statusCode == 200) {
      markAsRead(id);
    }
  }

  Future<void> callMarkAllAsRead() async {
    final ids = dataAllNotification.map((n) => n.id).toList();
    final response = await http.post(
      Uri.parse("${Constants.baseUrl}/api/notify/mark-all-read"),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userId': userId, 'notificationIds': ids}),
    );
    if (response.statusCode == 200) {
      markAllAsRead();
    }
  }

  void markAsRead(String id) {
    setState(() {
      final noti = dataAllNotification.firstWhere((n) => n.id == id);
      noti.isRead = true;
    });
  }

  void markAllAsRead() {
    setState(() {
      for (var noti in dataAllNotification) {
        noti.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotis = dataAllNotification.where((noti) {
      final matchesSearch = searchText.isEmpty ||
          noti.title.toLowerCase().contains(searchText.toLowerCase()) ||
          noti.message.toLowerCase().contains(searchText.toLowerCase());
      final matchesRead = !showOnlyUnread || !noti.isRead;
      return matchesSearch && matchesRead;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            icon: const Icon(Icons.done_all),
            onPressed: callMarkAllAsRead,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Checkbox(
                  value: showOnlyUnread,
                  onChanged: (val) {
                    setState(() {
                      showOnlyUnread = val!;
                    });
                  },
                ),
                const Text("Chỉ chưa đọc"),
                const Spacer(),
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "🔍 Tìm kiếm...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {
                        searchText = text;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => getNotifications(reset: true),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!isLoadingMore &&
                      hasMore &&
                      scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    getNotifications();
                  }
                  return false;
                },
                child: filteredNotis.isEmpty
                    ? const Center(child: Text("📭 Không có thông báo nào"))
                    : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: filteredNotis.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filteredNotis.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final noti = filteredNotis[index];
                    final formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(noti.createdAt);

                    return GestureDetector(
                      onTap: () => callMarkAsRead(noti.id),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: noti.isRead ? Colors.grey.shade300 : Colors.orange,
                            child: Icon(
                              noti.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  noti.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: noti.isRead ? Colors.grey : Colors.black87,
                                  ),
                                ),
                              ),
                              if (noti.isRead)
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(noti.message),
                              const SizedBox(height: 4),
                              Text(formattedDate,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
