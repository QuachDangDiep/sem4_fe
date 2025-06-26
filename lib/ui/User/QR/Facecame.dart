import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
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
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  String? _lastAttendanceDate;

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
  }

  Future<void> _loadAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final storedDate = prefs.getString('lastAttendanceDate');

    if (storedDate != currentDate) {
      // New day, reset status
      await prefs.setBool('hasCheckedIn', false);
      await prefs.setBool('hasCheckedOut', false);
      await prefs.setString('lastAttendanceDate', currentDate);
      setState(() {
        _hasCheckedIn = false;
        _hasCheckedOut = false;
        _lastAttendanceDate = currentDate;
      });
    } else {
      // Same day, load status
      setState(() {
        _hasCheckedIn = prefs.getBool('hasCheckedIn') ?? false;
        _hasCheckedOut = prefs.getBool('hasCheckedOut') ?? false;
        _lastAttendanceDate = storedDate;
      });
    }

    if (!_hasCheckedIn || !_hasCheckedOut) {
      await _requestPermissionsAndInitializeCamera();
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi quyền hoặc camera: $e')),
      );
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

      // Determine check-in or check-out
      final String attendanceType = _hasCheckedIn ? 'checkout' : 'checkin';

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
          'type': attendanceType, // Add type field
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update attendance status
        if (attendanceType == 'checkin') {
          await prefs.setBool('hasCheckedIn', true);
          setState(() => _hasCheckedIn = true);
        } else {
          await prefs.setBool('hasCheckedOut', true);
          setState(() => _hasCheckedOut = true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Chấm công ${attendanceType == 'checkin' ? 'vào' : 'ra'} thành công!')),
        );
        Navigator.of(context).pop({'status': 'success', 'type': attendanceType});
      } else {
        final message = response.body.isNotEmpty
            ? jsonDecode(response.body)['message'] ?? 'Lỗi không rõ'
            : 'Lỗi server';
        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi gửi dữ liệu: $e')),
      );
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

  @override
  void dispose() {
    _faceDetectionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildOverlayWithCameraOrImage() {
    final double width = MediaQuery.of(context).size.width * 0.8;
    final double height = MediaQuery.of(context).size.width * 1.2; // Vertically stretched oval

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
              width: width,
              height: height, // Taller oval frame
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
          child: const Text(
            'Vui lòng đưa khuôn mặt vào khung hình',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: ClipOval(
            child: Container(
              width: width,
              height: height, // Match the taller oval frame
              decoration: BoxDecoration(
                border: Border.all(
                  color: _capturedImage != null ? Colors.orange : Colors.grey,
                  width: 6, // Thicker border
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4), // Shadow for prominence
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isFaceDetected && !_isCapturing && _capturedImage == null)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1, // Lower position
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
        if (_isCapturing)
          Center(
            child: ClipOval(
              child: SizedBox(
                width: width,
                height: height,
                child: TweenAnimationBuilder<double>(
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
                ),
              ),
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
    if (_hasCheckedIn && _hasCheckedOut) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Bạn đã hoàn thành chấm công trong ngày hôm nay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

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