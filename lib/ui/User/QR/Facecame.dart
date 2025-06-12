import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:sem4_fe/Service/Constants.dart';


class FaceAttendanceScreen extends StatefulWidget {
  const FaceAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isUploading = false;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  Timer? _faceDetectionTimer;
  bool _isFaceDetected = false;
  bool _isCapturing = false;
  bool _showFlashEffect = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front);

      _controller = CameraController(frontCamera, ResolutionPreset.medium);

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
        _startFaceDetection();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi tạo camera: $e')),
      );
    }
  }

  void _startFaceDetection() {
    _faceDetectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isFaceDetected &&
          _capturedImage == null &&
          !_isCapturing &&
          _isCameraInitialized) {
        setState(() => _isFaceDetected = true);
        Future.delayed(const Duration(seconds: 1), () {
          _takePicture();
        });
      }
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _showFlashEffect = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showFlashEffect = false);
    });

    await Future.delayed(const Duration(seconds: 3));

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (!mounted) return;

      setState(() => _capturedImage = image);
      _faceDetectionTimer?.cancel();

      // ✅ Tự động gửi ảnh sau khi chụp xong
      await _sendImageToServer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp ảnh: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _sendImageToServer() async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);
    final uri = Uri.parse(Constants.attendanceUrl);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', _capturedImage!.path),
      );

      final response = await request.send();
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🟢 Gửi ảnh thành công!')),
          );

          // ✅ Thoát ra và trả kết quả sau khi gửi ảnh thành công
          Navigator.of(context).pop({
            'status': 'success',
            'time': DateTime.now().toIso8601String(),
            'data': jsonResponse,
            'message': 'Chấm công bằng khuôn mặt thành công'
          });
        }
      } else {
        final errorResponse = await response.stream.bytesToString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '🔴 Lỗi server: ${response.statusCode} - $errorResponse')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi gửi ảnh: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _faceDetectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildOverlayWithCameraOrImage() {
    final double size = MediaQuery.of(context).size.width * 0.8;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.7),
            BlendMode.srcOver,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: ClipOval(
            child: Container(
              width: size,
              height: size,
              child: _capturedImage == null
                  ? (_controller != null
                  ? CameraPreview(_controller!)
                  : Container(color: Colors.black))
                  : Image.file(
                File(_capturedImage!.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (_showFlashEffect)
          Container(
            color: Colors.white.withOpacity(0.9),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 30,
          left: 0,
          right: 0,
          child: Text(
            'Vui lòng đưa khuôn mặt vào khung hình',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: size,
            height: size,
            child: _isCapturing
                ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 3),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFF57C00)),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  value: value,
                );
              },
            )
                : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _capturedImage != null
                      ? Colors.orange
                      : Colors.grey,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        if (_isFaceDetected && !_isCapturing && _capturedImage == null)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: const Text(
              'ĐÃ PHÁT HIỆN KHUÔN MẶT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chấm công bằng khuôn mặt'),
        backgroundColor: Colors.orange[500],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        titleSpacing: -5,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : (_isCameraInitialized
          ? Column(
        children: [
          Expanded(child: _buildOverlayWithCameraOrImage()),
        ],
      )
          : const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang khởi tạo camera...'),
          ],
        ),
      )),
    );
  }
}
