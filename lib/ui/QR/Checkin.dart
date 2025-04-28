import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'Qrscanner.dart';

class CheckInPage extends StatefulWidget {
  final Function(String username, String password)? onLogin;

  const CheckInPage({Key? key, this.onLogin, required String username, required String token}) : super(key: key);

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  bool showQRCode = false;

  String getTodayDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chấm công"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    title: const Text('Thông báo'),
                    content: const Text(
                      'Nếu bạn quên chấm công kết thúc thì hệ thống sẽ tính là một ngày nghỉ, '
                          'hãy đảm bảo kết thúc chấm công trước lúc ra về bạn nhé.\n\n'
                          'Hãy liên hệ với chủ để được giải quyết và chấm bù công.',
                      style: TextStyle(fontSize: 15),
                    ),
                    actions: [
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Đóng',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Đăng Điệp - Chấm công", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            infoRow("Loại", "Chấm công theo ca - check in"),
            infoRow("Chấm công bằng", "Mã QR Code"),
            infoRow("Ngày chấm công", getTodayDate()),
            infoRow("Giờ check-in", "00:00 giờ"),
            Row(
              children: const [
                Text("On Time", style: TextStyle(color: Colors.green)),
                SizedBox(width: 10),
                Text("Bạn muộn 5 phút", style: TextStyle(color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Lịch sử trừ tiền", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("Không lý do"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text("Có lý do"),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QRScanPage()),
                  );

                  if (result != null) {
                    print("Dữ liệu quét được: $result");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Bạn đã chấm công thành công!")),
                    );
                  }
                },
                child: const Text("Bắt đầu chấm công 👣"),
              ),
            ),
            const SizedBox(height: 20),
            if (showQRCode)
              Center(
                child: QrImageView(
                  data: "employee_id:12345,date:2025-04-02,time:00:00",
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(color: Colors.grey))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
