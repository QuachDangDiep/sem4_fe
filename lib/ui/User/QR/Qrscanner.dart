import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRScannerScreen extends StatefulWidget {
  final String token;
  final int employeeId;
  final double latitude;
  final double longitude;

  const QRScannerScreen({
    Key? key,
    required this.token,
    required this.employeeId,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã QR chấm công'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: (BarcodeCapture capture) {
              if (_isProcessing || _isSuccess) return;

              final barcode = capture.barcodes.first;
              final qrCode = barcode.rawValue;

              if (qrCode != null) {
                _processQRCode(qrCode);
              }
            },
          ),

          // Overlay hướng dẫn
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isProcessing
                      ? 'Đang xử lý...'
                      : 'Quét mã QR tại đây',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Khung quét QR
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _QRScannerOverlay(),
              ),
            ),
          ),

          // Nút đóng
          if (!_isProcessing)
            Positioned(
              bottom: 40,
              right: 20,
              child: FloatingActionButton(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.red,
                child: const Icon(Icons.close),
              ),
            ),

          // Hiển thị khi xử lý thành công
          if (_isSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Chấm công thành công!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: const Text(
                          'ĐÓNG',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String qrCode) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Kiểm tra mã QR có hợp lệ không
      final qrCheckResponse = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/qrattendance/$qrCode'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (qrCheckResponse.statusCode != 200) {
        throw Exception('Mã QR không hợp lệ hoặc đã hết hạn');
      }

      // 2. Gửi dữ liệu chấm công (không cần ảnh face)
      final attendanceResponse = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/qrattendance'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'employeeId': widget.employeeId,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'qrCode': qrCode,
          'attendanceMethod': 'QR_GPS', // Phương thức chấm công
        }),
      );

      if (attendanceResponse.statusCode == 200) {
        setState(() => _isSuccess = true);
      } else {
        final errorData = jsonDecode(attendanceResponse.body);
        throw Exception(errorData['message'] ?? 'Lỗi khi chấm công');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }
}

class _QRScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final borderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Vẽ nền mờ xung quanh
    final outerPath = Path()..addRect(Rect.largest);
    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );
    final innerPath = Path()..addRect(innerRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      paint,
    );

    // Vẽ khung QR
    canvas.drawRect(innerRect, borderPaint);

    // Vẽ góc vuông
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Góc trên trái
    canvas.drawLine(
      innerRect.topLeft,
      innerRect.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      innerRect.topLeft,
      innerRect.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Góc trên phải
    canvas.drawLine(
      innerRect.topRight,
      innerRect.topRight - Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      innerRect.topRight,
      innerRect.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Góc dưới trái
    canvas.drawLine(
      innerRect.bottomLeft,
      innerRect.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      innerRect.bottomLeft,
      innerRect.bottomLeft - Offset(0, cornerLength),
      cornerPaint,
    );

    // Góc dưới phải
    canvas.drawLine(
      innerRect.bottomRight,
      innerRect.bottomRight - Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      innerRect.bottomRight,
      innerRect.bottomRight - Offset(0, cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}