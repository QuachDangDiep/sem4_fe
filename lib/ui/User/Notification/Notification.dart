import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sem4_fe/ui/User/models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sem4_fe/main.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class NotificationPage extends StatefulWidget {
  final String token;

  const NotificationPage({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<QuerySnapshot> _notificationStream;
  int unreadCount = 0;
  bool showOnlyUnread = false;
  String searchText = "";
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = JwtDecoder.decode(widget.token)['userId'];
    updateStream();
    fetchUnreadCount();
    setupForegroundHandler();
  }

  void updateStream() {
    Query baseQuery = FirebaseFirestore.instance
        .collection('notifications')
        .where('userIds', arrayContains: userId);

    if (showOnlyUnread) {
      baseQuery = baseQuery.where('isRead', isEqualTo: false);
    }

    if (searchText.isNotEmpty) {
      baseQuery = baseQuery.where('title', isGreaterThanOrEqualTo: searchText);
    }

    _notificationStream =
        baseQuery.orderBy('sentAt', descending: true).snapshots();
  }

  void fetchUnreadCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userIds', arrayContains: userId)
        .where('isRead', isEqualTo: false)
        .get();

    setState(() {
      unreadCount = snap.docs.length;
    });
  }

  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        //   showDialog(
        //     context: navigatorKey.currentContext!,
        //     builder: (_) => AlertDialog(
        //       title: Text(message.notification!.title ?? 'Thông báo'),
        //       content: Text(message.notification!.body ?? ''),
        //       actions: [
        //         TextButton(
        //           onPressed: () => Navigator.pop(context),
        //           child: Text('Đóng'),
        //         ),
        //       ],
        //     ),
        //   );
        fetchUnreadCount();
      }
    });
  }

  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
    fetchUnreadCount();
  }

  Future<void> deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .delete();
    fetchUnreadCount();
  }

  Future<void> deleteAll() async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userIds', arrayContains: userId)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }

    fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.delete_sweep), onPressed: deleteAll),
        ],
        backgroundColor: Colors.orange,
        centerTitle: true,
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
                      updateStream();
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (text) {
                      searchText = text;
                      updateStream();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _notificationStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("📭 Không có thông báo nào"));
                }

                final notiList = snapshot.data!.docs.map((doc) {
                  return AppNotification.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: notiList.length,
                  itemBuilder: (context, index) {
                    final noti = notiList[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: noti.isRead
                              ? Colors.grey.shade300
                              : Colors.orange,
                          child: Icon(
                            noti.isRead ? Icons.mark_email_read : Icons
                                .mark_email_unread,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          noti.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: noti.isRead ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          noti.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${noti.createdAt.hour.toString().padLeft(
                                  2, '0')}:${noti.createdAt.minute
                                  .toString()
                                  .padLeft(2, '0')}",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteNotification(noti.id),
                            ),
                          ],
                        ),
                        onTap: () => markAsRead(noti.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
