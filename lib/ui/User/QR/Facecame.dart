import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
    _requestPermissionsAndInitializeCamera();
  }

  Future<void> _requestPermissionsAndInitializeCamera() async {
    try {
      final locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) {
        throw Exception('Không có quyền truy cập vị trí');
      }
      await _initializeCamera();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Lỗi quyền hoặc camera: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium);

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
        _startFaceDetection();
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Lỗi khởi tạo camera: $e');
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

      await _sendImageToServer();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Lỗi chụp ảnh: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _sendImageToServer() async {
    if (_capturedImage == null) return;
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Token không tồn tại');

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['userId']?.toString() ?? decoded['sub']?.toString();
      if (userId == null) throw Exception('Không tìm thấy userId trong token');

      final employeeResponse = await http.get(
        Uri.parse(Constants.employeeIdByUserIdUrl(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (employeeResponse.statusCode != 200) {
        throw Exception('Không lấy được employeeId');
      }

      final employeeId = employeeResponse.body;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final imageBytes = await File(_capturedImage!.path).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(Constants.attendanceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'employeeId': employeeId,
          'imageBase64': base64Image,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final qrAttendanceRes = await http.get(
          Uri.parse(Constants.qrAttendancesByEmployeeUrl(employeeId)),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (qrAttendanceRes.statusCode == 200) {
          final List<dynamic> data = json.decode(qrAttendanceRes.body);
          data.sort((a, b) =>
              DateTime.parse(b['scanTime']).compareTo(DateTime.parse(a['scanTime'])));

          Map<String, dynamic>? checkIn, checkOut;
          for (var record in data) {
            if (record['status'] == 'CheckIn' && checkIn == null) {
              checkIn = record;
            } else if (record['status'] == 'CheckOut' && checkOut == null) {
              checkOut = record;
            }
            if (checkIn != null && checkOut != null) break;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Chấm công thành công!')),
          );

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
              },
            ],
          });
        } else {
          throw Exception('Lỗi khi lấy dữ liệu QR chấm công');
        }
      } else {
        String errorMessage = 'Lỗi server';

        try {
          final body = response.body;
          if (body.isNotEmpty) {
            final parsed = json.decode(body);
            if (parsed is Map && parsed['message'] != null) {
              errorMessage = parsed['message'];
            } else if (parsed is String) {
              errorMessage = parsed;
            } else {
              errorMessage = body;
            }
          }
        } catch (_) {
          errorMessage = response.body;
        }

        if (errorMessage.contains('Already checked in and out for today.')) {
          errorMessage = 'Bạn đã chấm công trong ngày hôm nay';
        } else if (errorMessage.contains('No work schedules found for today.')) {
          errorMessage = 'Bạn chưa đăng ký ca làm cho ngày hôm nay';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
      _isFaceDetected = false;
    });
    _startFaceDetection();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('❗ Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Đóng'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
          child: Container(width: double.infinity, height: double.infinity),
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
                  : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
            ),
          ),
        ),
        if (_showFlashEffect) Container(color: Colors.white.withOpacity(0.9)),
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
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF57C00)),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  value: value,
                );
              },
            )
                : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _capturedImage != null ? Colors.orange : Colors.grey,
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
            child: const Column(
              children: [
                Text(
                  'ĐÃ PHÁT HIỆN KHUÔN MẶT',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    if (_capturedImage == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _retakePicture,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
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
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleSpacing: -5,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : (_isCameraInitialized
          ? Column(
        children: [
          Expanded(child: _buildOverlayWithCameraOrImage()),
          _buildBottomButtons(),
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
