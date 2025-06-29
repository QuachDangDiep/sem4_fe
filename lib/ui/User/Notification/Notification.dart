import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:sem4_fe/ui/User/models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sem4_fe/main.dart';

class NotificationPage extends StatefulWidget {
  final String userId;
  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<QuerySnapshot> _notificationStream;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userIds', arrayContains: widget.userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    fetchUnreadCount();
    setupForegroundHandler();
  }

  void fetchUnreadCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userIds', arrayContains: widget.userId)
        .where('isRead', isEqualTo: false)
        .get();
    setState(() {
      unreadCount = snap.docs.length;
    });
  }

  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final title = message.notification!.title ?? 'Thông báo';
        final body = message.notification!.body ?? '';
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Đóng'))
            ],
          ),
        );
      }
    });
  }

  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).update({'isRead': true});
    fetchUnreadCount();
  }

  Future<void> deleteNotification(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
    fetchUnreadCount();
  }

  Future<void> deleteAll() async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userIds', arrayContains: widget.userId)
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
        title: Text('Thông báo'),
        actions: [
          badges.Badge(
            showBadge: unreadCount > 0,
            badgeContent: Text('$unreadCount', style: TextStyle(color: Colors.white)),
            child: IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {},
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: deleteAll,
          )
        ],
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Không có thông báo nào"));
          }

          List<AppNotification> notiList = snapshot.data!.docs.map((doc) {
            return AppNotification.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            itemCount: notiList.length,
            itemBuilder: (context, index) {
              final noti = notiList[index];
              return ListTile(
                leading: Icon(
                  noti.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: noti.isRead ? Colors.grey : Colors.orange,
                ),
                title: Text(noti.title),
                subtitle: Text(noti.message),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${noti.createdAt.hour}:${noti.createdAt.minute}"),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteNotification(noti.id),
                    ),
                  ],
                ),
                onTap: () => markAsRead(noti.id),
              );
            },
          );
        },
      ),
    );
  }
}
