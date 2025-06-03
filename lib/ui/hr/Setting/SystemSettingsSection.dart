import 'package:flutter/material.dart';

class SystemSettingsSection extends StatefulWidget {
  @override
  _SystemSettingsSectionState createState() => _SystemSettingsSectionState();
}

class _SystemSettingsSectionState extends State<SystemSettingsSection> {
  String selectedLanguage = 'Tiếng Việt';
  String selectedTimezone = '(GMT+7) Hồ Chí Minh';
  String selectedDateFormat = '30/05/2025';
  bool isDarkMode = false;

  List<String> languages = ['Tiếng Việt', 'English'];
  List<String> timezones = [
    '(GMT+7) Hồ Chí Minh',
    '(GMT+8) Singapore',
    '(GMT+9) Tokyo',
  ];
  List<String> dateFormats = ['30/05/2025', '05/30/2025', '2025-05-30'];

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Row(
        children: [
          Icon(Icons.settings, color: Colors.deepPurple),
          SizedBox(width: 10),
          Text('Cài đặt hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        Container(
          height: 400,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ngôn ngữ", style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: selectedLanguage,
                isExpanded: true,
                items: languages.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLanguage = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              Text("Múi giờ", style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: selectedTimezone,
                isExpanded: true,
                items: timezones.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTimezone = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              Text("Định dạng ngày", style: TextStyle(fontSize: 16)),
              Row(
                children: dateFormats.map((format) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedDateFormat = format;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedDateFormat == format
                              ? Colors.deepPurple.shade50
                              : Colors.white,
                          side: BorderSide(
                            color: selectedDateFormat == format
                                ? Colors.deepPurple
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          format,
                          style: TextStyle(
                            color: selectedDateFormat == format
                                ? Colors.deepPurple
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Text("Giao diện", style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.brightness_high),
                      label: Text("Sáng"),
                      onPressed: () {
                        setState(() {
                          isDarkMode = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isDarkMode ? Colors.deepPurple : Colors.grey.shade300,
                        foregroundColor: !isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.brightness_2),
                      label: Text("Tối"),
                      onPressed: () {
                        setState(() {
                          isDarkMode = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.deepPurple : Colors.grey.shade300,
                        foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Gửi dữ liệu hoặc cập nhật cài đặt
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã lưu thay đổi")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text("Lưu thay đổi"),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
