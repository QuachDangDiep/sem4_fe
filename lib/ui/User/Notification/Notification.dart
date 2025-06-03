import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // ✅ Quan trọng để màu AppBar chàn lên status bar
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.only(top: kToolbarHeight + 24), // ✅ Đẩy nội dung xuống dưới AppBar
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Không có dữ liệu',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 2, // mục "Thông báo"
      //   selectedItemColor: Colors.orange,
      //   unselectedItemColor: Colors.grey,
      //   onTap: (index) {
      //     // TODO: xử lý chuyển trang nếu cần
      //   },
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
      //     BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Đề xuất'),
      //     BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      //   ],
      // ),
    );
  }
}