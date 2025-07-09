import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sem4_fe/Service/Constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRScannerScreen extends StatefulWidget {
  final String token;

  const QRScannerScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _errorMessage;
  Map<String, dynamic>? _attendanceData;
  String? employeeId;

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    try {
      final token = widget.token;
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['userId'];

      final response = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          employeeId = response.body;
        });
      } else {
        throw Exception('Không lấy được employeeId từ userId');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi lấy employeeId: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã QR chấm công'),
        backgroundColor: Colors.orange,
        centerTitle: true,
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
              if (_isProcessing || _isSuccess || employeeId == null) return;

              final barcode = capture.barcodes.first;
              final qrCode = barcode.rawValue;

              if (qrCode != null) {
                _processQRCode(qrCode);
              }
            },
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isProcessing
                      ? 'Đang xử lý...'
                      : employeeId == null
                      ? 'Đang tải mã nhân viên...'
                      : 'Quét mã QR tại đây',
                  style: const TextStyle(
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
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _QRScannerOverlay(),
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
      final token = widget.token;
      final uuidRegex = RegExp(r'[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}');
      final match = uuidRegex.firstMatch(qrCode);
      if (match == null) throw Exception("QR không chứa UUID hợp lệ");

      final qrInfoId = match.group(0);

      final qrRes = await http.get(
        Uri.parse("${Constants.baseUrl}/api/qrcodes/$qrInfoId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (qrRes.statusCode != 200) {
        throw Exception('QR không hợp lệ hoặc không tìm thấy');
      }

      final attendanceResponse = await http.post(
        Uri.parse(Constants.qrScanUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'employee': {
            'employeeId': employeeId,
          },
          'qrInfo': {
            'qrInfoId': qrInfoId,
          }
        }),
      );

      if (attendanceResponse.statusCode != 200) {
        throw Exception('Lỗi khi tạo bản ghi chấm công: ${attendanceResponse.body}');
      }

// ✅ GỌI API để lấy danh sách chấm công mới
      final shiftsResponse = await http.get(
        Uri.parse(Constants.qrAttendancesByEmployeeUrl(employeeId!)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (shiftsResponse.statusCode == 200) {
        final List<dynamic> shifts = json.decode(shiftsResponse.body);

        // Sắp xếp giảm dần theo thời gian
        shifts.sort((a, b) =>
            DateTime.parse(b['scanTime']).compareTo(DateTime.parse(a['scanTime'])));

        Map<String, dynamic>? checkIn, checkOut;
        for (var record in shifts) {
          if (record['status'] == 'CheckIn' && checkIn == null) {
            checkIn = record;
          } else if (record['status'] == 'CheckOut' && checkOut == null) {
            checkOut = record;
          }
          if (checkIn != null && checkOut != null) break;
        }

        Navigator.of(context).pop({
          'status': 'success',
          'type': checkIn != null && checkOut == null ? 'checkin' : 'checkout',
          'shifts': [
            {
              'checkInTime': checkIn?['scanTime'] != null
                  ? DateFormat('HH:mm').format(DateTime.parse(checkIn!['scanTime']))
                  : '---',
              'checkOutTime': checkOut?['scanTime'] != null
                  ? DateFormat('HH:mm').format(DateTime.parse(checkOut!['scanTime']))
                  : '---',
            }
          ],
        });
      } else {
        throw Exception('Không thể lấy dữ liệu ca làm mới');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
      });
    } finally {
      setState(() {
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
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

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
    canvas.drawRect(innerRect, borderPaint);

    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

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