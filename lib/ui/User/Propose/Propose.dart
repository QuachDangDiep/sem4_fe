import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/LeaveRegistration.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/WorkSchedule.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/WorkSchedulePage.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/ChangeShiftPage.dart';
import 'package:sem4_fe/ui/User/Propose/Navbar/AttendanceAppealPage.dart';



class ProposalPage extends StatefulWidget {
  const ProposalPage({Key? key}) : super(key: key);

  @override
  State<ProposalPage> createState() => _ProposalPageState();
}

class _ProposalPageState extends State<ProposalPage> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    setState(() {
      _token = storedToken;
    });
  }

  void _navigateIfAuthenticated(BuildContext context, Widget page) {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

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
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Đề xuất',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          buildProposalItem(
            'Đăng ký nghỉ',
            Icons.airline_seat_individual_suite,
            Colors.orange,
                () => _navigateIfAuthenticated(
              context,
              LeaveRegistrationPage(token: _token!),
            ),
          ),
          buildProposalItem(
            'Đăng ký ca làm việc',
            Icons.note_alt,
            Colors.deepPurple,
                () => _navigateIfAuthenticated(
              context,
                  WeeklyShiftSelectionScreen(token: _token!),
            ),
          ),
          buildProposalItem(
            'Xem lịch làm việc',
            Icons.schedule,
            Colors.deepOrange,
                () => _navigateIfAuthenticated(
              context,
                  WeeklyShiftSelectionScreenHistory(token: _token!),
            ),
          ),
          // buildProposalItem(
          //   'Đổi ca',
          //   Icons.sync_alt,
          //   Colors.green,
          //       () {
          //     if (_token == null || _token!.isEmpty) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Vui lòng đăng nhập lại')),
          //       );
          //       return;
          //     }
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => ChangeShiftPage(token: _token!),
          //       ),
          //     );
          //   },
          // ),
          buildProposalItem(
            'Giải trình chấm công',
            Icons.report_problem,
            Colors.redAccent,
                () => _navigateIfAuthenticated(
              context,
              AttendanceAppealPage(token: _token!),
            ),
          ),

        ],
      ),
    );
  }
}
