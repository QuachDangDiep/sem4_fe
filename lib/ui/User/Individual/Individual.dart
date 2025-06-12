import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sem4_fe/ui/login/Login.dart';

class PersonalPage extends StatelessWidget {
  const PersonalPage({Key? key}) : super(key: key);

  Widget buildMenuItem(String title, IconData icon, VoidCallback onTap,
      {Color? backgroundColor}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: backgroundColor ?? Colors.blue,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.orange, // Màu của thanh status bar
        statusBarIconBrightness: Brightness.light, // Icon trắng cho Android
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.orange,
          centerTitle: true,
          elevation: 0,
          title: const Text('Cá nhân', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white,),
              onPressed: () {
                // TODO: Xử lý chức năng thoát
                showDialog(
                  context: context,
                  builder: (_) =>
                      AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text(
                            'Bạn có chắc muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                              // TODO: Thực hiện đăng xuất
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                );
              },
            )
          ],
        ),
        body: ListView(
          children: [
            buildMenuItem('Thông tin cá nhân', Icons.person, () {},
                backgroundColor: Colors.orange),
            buildMenuItem('Lịch sử chấm công', Icons.history, () {},
                backgroundColor: Colors.blue),
            buildMenuItem('Xếp ca làm việc', Icons.schedule, () {},
                backgroundColor: Colors.deepPurple),
            buildMenuItem('Chấm công hộ', Icons.assignment_ind, () {},
                backgroundColor: Colors.indigo),
            buildMenuItem('Bảng công', Icons.grid_on, () {},
                backgroundColor: Colors.cyan),
            buildMenuItem('Bảng phép, thâm niên', Icons.event_note, () {},
                backgroundColor: Colors.lightBlue),
            buildMenuItem('Phiếu lương', Icons.attach_money, () {},
                backgroundColor: Colors.green),
            buildMenuItem('Hợp đồng lao động', Icons.description, () {},
                backgroundColor: Colors.amber),
            buildMenuItem('Đổi mật khẩu', Icons.vpn_key, () {},
                backgroundColor: Colors.teal),
            const SizedBox(height: 20),
          ],
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //   currentIndex: 3,
        //   selectedItemColor: Colors.orange,
        //   unselectedItemColor: Colors.grey,
        //   items: const [
        //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        //     BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Đề xuất'),
        //     BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
        //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        //   ],
        //   onTap: (index) {
        //     // TODO: Chuyển trang theo index
        //   },
        // ),
      ),
    );
  }
}
