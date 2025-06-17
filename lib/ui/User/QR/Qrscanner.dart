import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sem4_fe/Service/Constants.dart';

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
  Map<String, dynamic>? _attendanceData;

  Map<String, String> _parseQRCode(String qrCode) {
    final parts = qrCode.split('-');
    return {
      'code': parts.length > 0 ? parts[0] : '',
      'location': parts.length > 5 ? parts[5] : 'Unknown',
    };
  }

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
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => setState(() => _errorMessage = null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('THỬ LẠI'),
                          ),
                        ],
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
                      if (_attendanceData != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Mã QR: ${_attendanceData!['qrId']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mã nhân viên: ${_attendanceData!['employeeId']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Phương thức: ${_attendanceData!['attendanceMethod']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
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
      _isSuccess = false;
      _attendanceData = null;
    });

    try {

      // Phân tích mã QR
      final qrData = _parseQRCode(qrCode);
      print('Mã QR phân tích: ${qrData['code']}, Vị trí: ${qrData['location']}');

      // ... (phần còn lại của hàm _processQRCode)

      // Khi hiển thị kết quả, có thể thêm thông tin vị trí
      if (_isSuccess && _attendanceData != null) {
        _attendanceData!['location'] = qrData['location'];
      }
      // Kiểm tra định dạng mã QR trước khi gửi
      if (qrCode.isEmpty || !_isValidQRFormat(qrCode)) {
        throw FormatException('Mã QR không đúng định dạng');
      }

      print('[DEBUG] Mã QR nhận được: $qrCode');

      // 1. Kiểm tra mã QR
      final qrCheckUri = Uri.parse(Constants.searchQrCodeUrl(qrCode));
      print('[DEBUG] Gọi API kiểm tra QR: ${qrCheckUri.toString()}');

      final qrCheckResponse = await http.get(
        qrCheckUri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] Phản hồi kiểm tra QR: ${qrCheckResponse.body}');

      if (qrCheckResponse.statusCode != 200) {
        final errorData = jsonDecode(qrCheckResponse.body);
        throw Exception(errorData['message'] ?? 'Mã QR không hợp lệ');
      }

      // 2. Gửi dữ liệu chấm công
      final attendanceUri = Uri.parse(Constants.attendanceUrl);
      final requestBody = jsonEncode({
        'employeeId': widget.employeeId,
        'qrCode': qrCode,
        'attendanceMethod': 'QR',
        // Thêm các trường bắt buộc khác nếu cần
        'location': 'Công ty FP1', // Thêm thông tin vị trí từ QR
      });

      print('[DEBUG] Gửi dữ liệu chấm công: $requestBody');

      final attendanceResponse = await http.post(
        attendanceUri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(attendanceResponse.body);
      print('[DEBUG] Phản hồi chấm công: $responseData');

      if (attendanceResponse.statusCode == 200) {
        // Kiểm tra các trường bắt buộc trong response
        if (responseData['qrId'] == null ||
            responseData['employeeId'] == null) {
          throw Exception('Thiếu thông tin bắt buộc từ server');
        }

        setState(() {
          _isSuccess = true;
          _attendanceData = {
            'qrId': responseData['qrId'],
            'employeeId': responseData['employeeId'].toString(),
            'attendanceMethod': responseData['attendanceMethod'] ?? 'QR',
            'location': responseData['location'] ?? 'Công ty FP1',
          };
        });
      } else {
        throw Exception(responseData['message'] ?? 'Lỗi khi chấm công');
      }
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = 'Lỗi định dạng: ${e.message}\nVui lòng quét lại mã QR';
      });
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.message}\nKiểm tra mạng và thử lại';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e
            .toString()
            .split('\n')
            .first}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _isValidQRFormat(String qrCode) {
    // Thêm logic kiểm tra định dạng mã QR của bạn
    // Ví dụ: mã QR phải chứa "Cong ty FP1"
    return qrCode.contains('Cong ty FP1') && qrCode.length > 10;
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