import 'package:flutter/material.dart';

class NotificationSettingsSection extends StatefulWidget {
  @override
  _NotificationSettingsSectionState createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  bool emailNotification = true;
  bool pushNotification = true;
  bool chamCong = true;
  bool nghiPhep = true;
  bool baoCao = false;

  String selectedFrequency = 'Hằng ngày';
  final List<String> frequencies = ['Hằng ngày', 'Hằng tuần', 'Hằng tháng'];

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.notifications_none, color: Colors.deepPurple),
      title: Text(
        'Thông báo',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        // Giới hạn chiều cao phần nội dung với ScrollView bên trong
        Container(
          height: 300, // ví dụ giới hạn chiều cao 300 px, bạn chỉnh tùy ý
          child: SingleChildScrollView(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Email thông báo'),
                  subtitle: Text('Nhận thông báo qua email'),
                  value: emailNotification,
                  onChanged: (value) {
                    setState(() => emailNotification = value);
                  },
                  activeColor: Colors.deepPurple,
                ),
                SwitchListTile(
                  title: Text('Push notification'),
                  subtitle: Text('Nhận thông báo trên thiết bị'),
                  value: pushNotification,
                  onChanged: (value) {
                    setState(() => pushNotification = value);
                  },
                  activeColor: Colors.deepPurple,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Tần suất thông báo'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedFrequency,
                    items: frequencies
                        .map((freq) =>
                        DropdownMenuItem(value: freq, child: Text(freq)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedFrequency = value!);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Loại thông báo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SwitchListTile(
                  title: Text('Chấm công'),
                  value: chamCong,
                  onChanged: (value) {
                    setState(() => chamCong = value);
                  },
                  activeColor: Colors.deepPurple,
                ),
                SwitchListTile(
                  title: Text('Nghỉ phép'),
                  value: nghiPhep,
                  onChanged: (value) {
                    setState(() => nghiPhep = value);
                  },
                  activeColor: Colors.deepPurple,
                ),
                SwitchListTile(
                  title: Text('Báo cáo'),
                  value: baoCao,
                  onChanged: (value) {
                    setState(() => baoCao = value);
                  },
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
