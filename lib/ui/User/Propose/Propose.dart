import 'package:flutter/material.dart';

class ProposalPage extends StatelessWidget {
  const ProposalPage({Key? key}) : super(key: key);

  Widget buildProposalItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(useMaterial3: false), // Tắt Material 3 cho riêng trang này
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Đề xuất',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: kToolbarHeight + 24),
          children: [
            buildProposalItem('Đăng ký nghỉ', Icons.airline_seat_individual_suite, Colors.orange, () {}),
            buildProposalItem('Đi muộn về sớm', Icons.access_time, Colors.green, () {}),
            buildProposalItem('Làm thêm giờ', Icons.calculate, Colors.blue, () {}),
            buildProposalItem('Làm việc ngoài công ty, công tác', Icons.group_work, Colors.purple, () {}),
            buildProposalItem('Giải trình chấm công', Icons.note_alt, Colors.deepOrange, () {}),
            buildProposalItem('Đổi ca', Icons.sync_alt, Colors.green, () {}),
            buildProposalItem('Đăng ký ra ngoài', Icons.double_arrow, Colors.indigo, () {}),
          ],
        ),
      ),
    );
  }
}