import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final String username;
  final String token;

  const QRScannerScreen({Key? key, required this.username, required this.token}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? qrResult;
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: (BarcodeCapture capture) {
              if (_isScanned) return;

              final barcode = capture.barcodes.first;
              final code = barcode.rawValue;

              if (code != null) {
                setState(() {
                  _isScanned = true;
                  qrResult = code;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('QR: $code')),
                );

                // Quay lại sau 2 giây với kết quả
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pop(context, code);
                });
              }
            },
          ),
          Positioned(
            top: 60,
            child: const Text(
              'Quét mã để chấm công',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Positioned(
            bottom: 40,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: Icon(Icons.close, color: Colors.black),
              ),
            ),
          ),
          // Overlay tương tự như QrScannerOverlayShape
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScannerOverlayPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    final double cutOutSize = 250;
    final double left = (size.width - cutOutSize) / 2;
    final double top = (size.height - cutOutSize) / 2;
    final Rect outerRect = Offset.zero & size;
    final Rect cutOutRect = Rect.fromLTWH(left, top, cutOutSize, cutOutSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(outerRect),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, const Radius.circular(10))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, const Radius.circular(10)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
